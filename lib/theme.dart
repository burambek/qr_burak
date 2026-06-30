import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


//
const kApiGetFields = 'https://cza.sytes.net:6587/IgorZavod/hs/Zav/GetFields';
const kApiGetTTN    = 'https://cza.sytes.net:6587/IgorZavod/hs/Zav/GetTTN';
const kApiWriteTTN  = 'https://cza.sytes.net:6587/IgorZavod/hs/Zav/WriteTTN';
const kApiListTTN = 'https://cza.sytes.net:6587/IgorZavod/hs/Zav/ListTTN';

// ── Brand colors ──────────────────────────────────────
const kGreen        = Color(0xFF2E7D32);
const kGreenLight   = Color(0xFFE8F5E9);
const kGreenMid     = Color(0xFF43A047);
const kBrown        = Color(0xFF4E342E);
const kBrownLight   = Color(0xFFF3E5DC);
const kBrownMid     = Color(0xFF8D6E63);
const kGray         = Color(0xFF616161);
const kGrayLight    = Color(0xFFF5F5F5);
const kGrayMid      = Color(0xFFBDBDBD);
const kErrorRed     = Color(0xFFC62828);
const kErrorLight   = Color(0xFFFFEBEE);
const kWhite        = Colors.white;

// ── Shadows ───────────────────────────────────────────
const kCardShadow = [
  BoxShadow(
    color: Color(0x14000000),
    blurRadius: 8,
    offset: Offset(0, 2),
    spreadRadius: 0,
  ),
];

const kElevatedShadow = [
  BoxShadow(
    color: Color(0x20000000),
    blurRadius: 16,
    offset: Offset(0, 4),
    spreadRadius: 0,
  ),
];

const kButtonShadow = [
  BoxShadow(
    color: Color(0x3D2E7D32),
    blurRadius: 8,
    offset: Offset(0, 4),
    spreadRadius: 0,
  ),
];




// ── App theme ─────────────────────────────────────────
final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kGreen,
    primary: kGreen,
    secondary: kBrown,
    error: kErrorRed,
    surface: kWhite,
  ),
  scaffoldBackgroundColor: const Color(0xFFF0F0EC),

  appBarTheme: const AppBarTheme(
    backgroundColor: kGreen,
    foregroundColor: kWhite,
    elevation: 4,
    shadowColor: Color(0x3D000000),
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
    titleTextStyle: TextStyle(
      color: kWhite,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
    ),
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: kWhite,
    selectedItemColor: kGreen,
    unselectedItemColor: kGrayMid,
    selectedLabelStyle: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 15,
    ),
    unselectedLabelStyle: TextStyle(fontSize: 12),
    showUnselectedLabels: true,
    elevation: 15,
    type: BottomNavigationBarType.fixed,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kGreen,
      foregroundColor: kWhite,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kBrown,
      side: const BorderSide(color: kBrown, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
  ),

  cardTheme: CardThemeData(
    color: kWhite,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  ),

  dividerTheme: const DividerThemeData(
    color: Color(0xFFE0E0E0),
    thickness: 0.8,
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kGrayMid),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kGreen, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kErrorRed),
    ),
    labelStyle: const TextStyle(color: kGray),
  ),

  fontFamily: 'Roboto',
);