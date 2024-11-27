import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> prayerTimes = {};
  String hadith = '';

  @override
  void initState() {
    super.initState();
    fetchPrayerTimes();
    fetchHadith();
  }

  Future<void> fetchPrayerTimes() async {
    final response = await http.get(Uri.parse(
        'https://api.aladhan.com/timingsByAddress?address=Prestwitch,20UK&method=99&methodSettings=18.5,null,17.5'));
    if (response.statusCode == 200) {
      setState(() {
        prayerTimes = json.decode(response.body)['data']['timings'];
      });
    }
  }

  Future<void> fetchHadith() async {
    final response = await http
        .get(Uri.parse('https://random-hadith-generator.vercel.app/bukhari/'));
    if (response.statusCode == 200) {
      setState(() {
        hadith = json.decode(response.body)['data']['hadith_english'];
      });
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300, // Increased height to accommodate all content
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: ResponsiveHeader(),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ResponsiveTitle('Prayer Times'),
                  SizedBox(height: 16),
                  if (prayerTimes.isNotEmpty)
                    ...prayerTimes.entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AutoSizeText(
                                entry.key,
                                style: GoogleFonts.inter(),
                                maxLines: 1,
                              ),
                            ),
                            Expanded(
                              child: AutoSizeText(
                                entry.value,
                                style: GoogleFonts.inter(),
                                maxLines: 1,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()
                  else
                    Center(child: CircularProgressIndicator()),
                  SizedBox(height: 32),
                  ResponsiveTitle('Daily Hadith'),
                  SizedBox(height: 16),
                  if (hadith.isNotEmpty)
                    AutoSizeText(
                      hadith,
                      style: GoogleFonts.inter(),
                      minFontSize: 12,
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Center(child: CircularProgressIndicator()),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResponsiveHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final logoSize = maxHeight * 0.3;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: maxWidth * 0.05, vertical: maxHeight * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/mosque-logo-OFPRQdnu33asc6aO72ajzsh8yqR1D2.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: maxHeight * 0.01),
                  AutoSizeText(
                    'Ikhlass Masjid',
                    style: GoogleFonts.inter(
                      fontSize: maxWidth * 0.08,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    minFontSize: 20,
                  ),
                  SizedBox(height: maxHeight * 0.02),
                  AutoSizeText(
                    'Manchester',
                    style: GoogleFonts.inter(
                      fontSize: maxWidth * 0.05,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    minFontSize: 16,
                  ),
                  SizedBox(height: maxHeight * 0.03),
                  AutoSizeText(
                    'Towards a Peaceful and Cohesive Community',
                    style: GoogleFonts.inter(
                      fontSize: maxWidth * 0.03,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 12,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ResponsiveTitle extends StatelessWidget {
  final String text;

  ResponsiveTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}