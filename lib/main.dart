import 'package:flutter/material.dart';
import 'package:presensi_fa_mobile/pages/dashboard_page.dart';
import 'package:presensi_fa_mobile/pages/login_page.dart';
import 'package:presensi_fa_mobile/pages/main_page.dart';
import 'package:presensi_fa_mobile/pages/members_page.dart';
import 'package:presensi_fa_mobile/pages/presence_add_page.dart';
import 'package:presensi_fa_mobile/pages/presence_page.dart';
import 'package:presensi_fa_mobile/pages/profile_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/main',
      onGenerateRoute: (settings) {
        if (settings.name == '/presence') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PresencePage(role: args['role']),
          );
        }

        // Default routes
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (context) => LoginPage());
          case '/main':
            return MaterialPageRoute(builder: (context) => MainPage());
          case '/dashboard':
            return MaterialPageRoute(builder: (context) => DashboardPage());
          case '/members':
            return MaterialPageRoute(builder: (context) => MembersScreen());
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
