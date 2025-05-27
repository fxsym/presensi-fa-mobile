import 'package:flutter/material.dart';
import 'package:presensi_fa_mobile/pages/dashboard_page.dart';
import 'package:presensi_fa_mobile/pages/home_page.dart';
import 'package:presensi_fa_mobile/pages/honors_page.dart';
import 'package:presensi_fa_mobile/pages/login_page.dart';
import 'package:presensi_fa_mobile/pages/main_page.dart';
import 'package:presensi_fa_mobile/pages/members_page.dart';
import 'package:presensi_fa_mobile/pages/presence_add_page.dart';
import 'package:presensi_fa_mobile/pages/presence_page.dart';
import 'package:presensi_fa_mobile/pages/profile_page.dart';
import 'package:presensi_fa_mobile/pages/register_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/presence') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PresencePage(role: args['role']),
          );
        }

        // Default routes
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => HomePage());
          case '/login':
            return MaterialPageRoute(builder: (context) => LoginPage());
          case '/register':
            return MaterialPageRoute(builder: (context) => RegisterPage());
          case '/main':
            return MaterialPageRoute(builder: (context) => MainPage());
          case '/dashboard':
            return MaterialPageRoute(builder: (context) => DashboardPage());
          case '/members':
            return MaterialPageRoute(builder: (context) => MembersScreen());
          case '/honors':
            return MaterialPageRoute(builder: (context) => HonorsPage());
          case '/presence/add':
            return MaterialPageRoute(builder: (context) => PresenceAddPage());
          case '/profile':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder:
                  (context) => ProfileEditScreen(
                    user: args['user'],
                    onUpdateUser: args['onUpdateUser'],
                  ),
            );
          default:
            return null;
        }
      },
    );
  }
}
