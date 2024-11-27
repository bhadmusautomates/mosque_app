import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

class DateTimeDisplay extends StatelessWidget {
  final DateTime currentTime;

  const DateTimeDisplay({Key? key, required this.currentTime}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gregorianDate = DateFormat('EEEE, MMMM d, y').format(currentTime);
    final hijriDate = HijriCalendar.fromDate(currentTime);
    final time = DateFormat('h:mm:ss a').format(currentTime);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFF6B46C1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            gregorianDate,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B46C1),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            '${hijriDate.toFormat("MMMM d, yyyy")} AH',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Color(0xFF6B46C1).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B46C1),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}