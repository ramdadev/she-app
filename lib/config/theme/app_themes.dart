// Flutter imports:
import 'package:flutter/material.dart';

ThemeData theme() {
  return ThemeData(
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: appBarTheme(),
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue[700]!),
    useMaterial3: true,
    fontFamily: 'Poppins',
  );
}

AppBarTheme appBarTheme() {
  return const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    scrolledUnderElevation: 0.0,
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20.0,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.bold,
    ),
  );
}
