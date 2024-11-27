import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/time_display.dart';
import 'package:intl/intl.dart';
import 'dart:async';

void main() {
  runApp(AlIkhlassApp());
}

class AlIkhlassApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ikhlass Masjid',
      theme: ThemeData(
        primaryColor: Color(0xFF6B46C1),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Color(0xFFDAA520),
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, Map<String, List<String>>>> prayerTimesList = [];
  String hadith = '';
  String hadithRefNo = '';
  DateTime currentTime = DateTime.now();
  String lastUpdateDate = '';
  List<DateTime> fetchedDates = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTimeUpdates();
  }

  Future<void> _loadData() async {
    await fetchPrayerTimes();
    await fetchHadith();
  }

  void _startTimeUpdates() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          DateTime now = DateTime.now();
          if (now.day != currentTime.day) {
            _loadData();
          }
          currentTime = now;
        });
      }
    });
  }

  Future<void> fetchPrayerTimes() async {
    try {
      final bytes = await rootBundle.load('assets/prayer_table.xlsx');
      final excel = Excel.decodeBytes(bytes.buffer.asUint8List());
      final sheet = excel.tables[excel.tables.keys.first]!;

      final now = DateTime.now();
      final dates = List.generate(7, (index) => now.add(Duration(days: index - 3)));

      int dateColumnIndex = -1;
      Map<String, int> headerIndices = {};

      for (int col = 0; col < sheet.maxColumns; col++) {
        final cellValue = sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
            .value
            .toString();
        if (cellValue == 'Prayer_Date') {
          dateColumnIndex = col;
        } else if ([
          'Fajr_Start',
          'Fajr_Prayer',
          'Sunrise',
          'Dhuhr_Start',
          'Dhuhr_Prayer',
          'Asr_Start_Shafi',
          'Asr_Prayer',
          'Maghrib_Prayer',
          'Isha_Start',
          'Isha_Prayer'
        ].contains(cellValue)) {
          headerIndices[cellValue] = col;
        }
      }

      if (dateColumnIndex == -1 || headerIndices.length != 10) {
        throw Exception("Required columns not found in the Excel file");
      }

      prayerTimesList = [];
      fetchedDates = [];

      for (DateTime date in dates) {
        final currentDate = date.toUtc().toIso8601String().split('T')[0] + 'T00:00:00.000Z';
        bool foundDate = false;

        for (int row = 1; row < sheet.maxRows; row++) {
          final dateCell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: dateColumnIndex, rowIndex: row));
          final dateCellValue = dateCell.value.toString();
          if (dateCellValue == currentDate) {
            foundDate = true;
            Map<String, List<String>> prayerTimes = {
              'Fajr': [
                _formatTime(sheet
                    .cell(CellIndex.indexByColumnRow(
                        columnIndex: headerIndices['Fajr_Start']!,
                        rowIndex: row))
                    .value
                    .toString()),
                _formatTime(sheet
                    .cell(CellIndex.indexByColumnRow(
                        columnIndex: headerIndices['Fajr_Prayer']!,
                        rowIndex: row))
                    .value
                    .toString()),
              ],
              'Sunrise': [
                _formatTime(sheet
                    .cell(CellIndex.indexByColumnRow(
                        columnIndex: headerIndices['Sunrise']!, rowIndex: row))
                    .value
                    .toString()),
                '-',
              ],
              'Dhuhr': [
                _formatTime(sheet
                        .cell(CellIndex.indexByColumnRow(
                            columnIndex: headerIndices['Dhuhr_Start']!,
                            rowIndex: row))
                        .value
                        .toString())
                    .replaceAll('am', 'pm'),
                _formatTime(sheet
                        .cell(CellIndex.indexByColumnRow(
                            columnIndex: headerIndices['Dhuhr_Prayer']!,
                            rowIndex: row))
                        .value
                        .toString())
                    .replaceAll('am', 'pm'),
              ],
              'Asr': [
                _formatTime(sheet
                        .cell(CellIndex.indexByColumnRow(
                            columnIndex: headerIndices['Asr_Start_Shafi']!,
                            rowIndex: row))
                        .value
                        .toString())
                    .replaceAll('am', 'pm'),
                _formatTime(sheet
                        .cell(CellIndex.indexByColumnRow(
                            columnIndex: headerIndices['Asr_Prayer']!,
                            rowIndex: row))
                        .value
                        .toString())
                    .replaceAll('am', 'pm'),
              ],
              'Maghrib': [
                '-',
                _formatTime(sheet
                        .cell(CellIndex.indexByColumnRow(
                            columnIndex: headerIndices['Maghrib_Prayer']!,
                            rowIndex: row))
                        .value
                        .toString())
                    .replaceAll('am', 'pm'),
              ],
              'Isha': [
                _formatTime(sheet
                        .cell(CellIndex.indexByColumnRow(
                            columnIndex: headerIndices['Isha_Start']!,
                            rowIndex: row))
                        .value
                        .toString())
                    .replaceAll('am', 'pm'),
                _formatTime(sheet
                        .cell(CellIndex.indexByColumnRow(
                            columnIndex: headerIndices['Isha_Prayer']!,
                            rowIndex: row))
                        .value
                        .toString())
                    .replaceAll('am', 'pm'),
              ],
            };
            prayerTimesList.add({DateFormat('yyyy-MM-dd').format(date): prayerTimes});
            fetchedDates.add(date);
            break;
          }
        }

        if (!foundDate) {
          prayerTimesList.add({DateFormat('yyyy-MM-dd').format(date): {}});
          fetchedDates.add(date);
        }
      }

      setState(() {});
    } catch (e) {
      print("Error loading prayer times: $e");
      setState(() {
        prayerTimesList = List.generate(7, (index) => {
          DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: index - 3))): {}
        });
        fetchedDates = List.generate(7, (index) => DateTime.now().add(Duration(days: index - 3)));
      });
    }
  }

  String _formatTime(String time) {
    time = time.trim();

    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) {
      int hour = int.parse(time.split(':')[0]);
      String period = hour < 12 ? 'am' : 'pm';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:${time.split(':')[1]} $period';
    }

    if (RegExp(r'^\d{1}:\d{2}$').hasMatch(time)) {
      time = time.padLeft(5, '0');
      int hour = int.parse(time.split(':')[0]);
      String period = hour < 12 ? 'am' : 'pm';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:${time.split(':')[1]} $period';
    }

    if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(time)) {
      time = time.substring(0, 5);
      int hour = int.parse(time.split(':')[0]);
      String period = hour < 12 ? 'am' : 'pm';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:${time.split(':')[1]} $period';
    }

    if (RegExp(r'^\d{3,4}$').hasMatch(time)) {
      String paddedTime = time.padLeft(4, '0');
      int hour = int.parse(paddedTime.substring(0, 2));
      String period = hour < 12 ? 'am' : 'pm';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:${paddedTime.substring(2)} $period';
    }

    print('Unexpected time format: $time');
    return time;
  }

  Future<void> fetchHadith() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchDate = prefs.getString('lastHadithFetchDate');
    final currentDate = DateTime.now().toIso8601String().split('T')[0];

    if (lastFetchDate != currentDate) {
      final response = await http.get(
          Uri.parse('https://random-hadith-generator.vercel.app/bukhari/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          hadith = data['hadith_english'];
          hadithRefNo = data['refno'];
        });
        await prefs.setString('lastHadithFetchDate', currentDate);
        await prefs.setString('cachedHadith', hadith);
        await prefs.setString('cachedHadithRefNo', hadithRefNo);
      }
    } else {
      setState(() {
        hadith = prefs.getString('cachedHadith') ?? '';
        hadithRefNo = prefs.getString('cachedHadithRefNo') ?? '';
      });
    }
  }

  void shareContent() {
    String content = 'Check out Ikhlass Masjid!\n\n';
    content += 'Hadith of the Day:\n$hadith\n\n';
    content += 'Reference: $hadithRefNo\n';
    content += 'Prayer Times for ${DateFormat('EEEE, MMMM d, y').format(DateTime.now())}:\n';
    prayerTimesList[3].values.first.forEach((key, value) {
      content += '$key: Start - ${value[0]}, Jamaat - ${value[1]}\n';
    });
    Share.share(content);
  }

  Widget _buildCircularButton(
      String title, VoidCallback onTap, Color color, double size) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.all(size * 0.05),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.all(size * 0.1),
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: size * 0.16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenDialog(
      BuildContext context, String title, Widget content) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: content,
              ),
            ),
          );
        },
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildPrayerTimesContent() {
    if (prayerTimesList.isEmpty) {
      return Center(
        child: Text(
          'Unable to load prayer times. Please try again later.',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    return DefaultTabController(
      length: 7,
      initialIndex: 3,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: List.generate(7, (index) => Tab(
                text: DateFormat('EEE\ndd/MM').format(fetchedDates[index]),
              ),
            ),
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: List.generate(7, (index) => _buildDayPrayerTimes(index)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPrayerTimes(int index) {
    final prayerTimes = prayerTimesList[index].values.first;
    final date = fetchedDates[index];
    final dateFormat = DateFormat('EEEE, MMMM d, y');

    return Column(
      children: [
        Text(
          dateFormat.format(date),
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Prayer',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Expanded(
                child: Text(
                  'Start',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Jamaat',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        ...prayerTimes.entries
            .map((entry) => _buildPrayerRow(entry.key, entry.value))
            .toList(),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 16),
      ),
    );
  }

  Widget _buildHadithContent() {
    return hadith.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hadith, style: GoogleFonts.inter(fontSize: 18)),
              SizedBox(height: 16),
              Text(
                'Reference: $hadithRefNo',
                style: GoogleFonts.inter(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          )
        : Center(child: CircularProgressIndicator());
  }

  Widget _buildDonationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ikhlass Masjid, Lloyds Bank.',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16),
        _buildDonationInfo('Sort Code:', '30-95-42'),
        SizedBox(height: 8),
        _buildDonationInfo('Account Number:', '77763460'),
      ],
    );
  }

  Widget _buildDonationInfo(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerRow(String prayerName, List<String> times) {
    return Container(
      decoration: BoxDecoration(
        color: ['Fajr', 'Dhuhr', 'Maghrib'].contains(prayerName)
            ? Colors.grey[100]
            : Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  SizedBox(width: 8),
                  _getPrayerIcon(prayerName),
                  SizedBox(width: 12),
                  Text(
                    prayerName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                times[0],
                style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                times[1],
                style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPrayerIcon(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return Icon(FontAwesomeIcons.sun, color: Colors.blue, size: 20);
      case 'sunrise':
        return Icon(FontAwesomeIcons.solidSun, color: Colors.orange, size: 20);
      case 'dhuhr':
        return Icon(FontAwesomeIcons.sun, color: Colors.red, size: 20);
      case 'asr':
        return Icon(FontAwesomeIcons.cloudSun, color: Colors.purple, size: 20);
      case 'maghrib':
        return Icon(FontAwesomeIcons.solidMoon,
            color: Colors.deepPurple, size: 20);
      case 'isha':
        return Icon(FontAwesomeIcons.moon, color: Colors.indigo, size: 20);
      default:
        return Icon(FontAwesomeIcons.mosque, color: Colors.grey, size: 20);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final shortestSide = min(screenSize.width, screenSize.height);
    final buttonSize = shortestSide * 0.28;
    final circleSize = shortestSide * 0.75;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: shareContent,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: screenSize.height * 0.25,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: shortestSide * 0.08,
                        backgroundImage: NetworkImage(
                          'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/mosque-logo-OFPRQdnu33asc6aO72ajzsh8yqR1D2.png',
                        ),
                        backgroundColor: Colors.white,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Ikhlass Masjid',
                        style: GoogleFonts.inter(
                          fontSize: shortestSide * 0.09,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manchester',
                        style: GoogleFonts.inter(
                          fontSize: shortestSide * 0.05,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Towards a Peaceful and Cohesive Community',
                        style: GoogleFonts.inter(
                          fontSize: shortestSide * 0.025,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: DateTimeDisplay(currentTime: currentTime),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                          ),
                        ),
                        Positioned(
                          top: circleSize * 0.05,
                          child: _buildCircularButton(
                            'Daily Prayer Times',
                            () => _showFullScreenDialog(
                              context,
                              'Daily Prayer Times',
                              _buildPrayerTimesContent(),
                            ),
                            Color(0xFF6B46C1),
                            buttonSize,
                          ),
                        ),
                        Positioned(
                          bottom: circleSize * 0.15,
                          left: circleSize * 0.15,
                          child: _buildCircularButton(
                            'Hadith of the Day',
                            () => _showFullScreenDialog(
                              context,
                              'Hadith of the Day',
                              _buildHadithContent(),
                            ),
                            Color(0xFF9F7AEA),
                            buttonSize,
                          ),
                        ),
                        Positioned(
                          bottom: circleSize * 0.15,
                          right: circleSize * 0.15,
                          child: _buildCircularButton(
                            'Please Donate',
                            () => _showFullScreenDialog(
                              context,
                              'Please Donate',
                              _buildDonationContent(),
                            ),
                            Color(0xFFDAA520),
                            buttonSize,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Indeed, prayer has been decreed upon the believers a decree of specified times.\n Surah An-Nisa: 103',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      fontSize: shortestSide * 0.03,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}