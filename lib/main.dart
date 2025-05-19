import 'package:flutter/material.dart';
import 'package:presensi_fa_mobile/pages/dashboard_page.dart';
import 'package:presensi_fa_mobile/pages/login_page.dart';
import 'package:presensi_fa_mobile/pages/main_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        // '/splash': (context) => SplashPage(),
        // '/': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/main': (context) => MainPage(),
        '/dashboard': (context) => DashboardPage(),
      },
    );
  }
}