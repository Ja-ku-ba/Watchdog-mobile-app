import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watchdog/services/auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLayout extends StatefulWidget {
  final Widget child;

  const AppLayout({required this.child, super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();

  static Future<void> logoutUser(context) async {
    AuthService.logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }
}

class _AppLayoutState extends State<AppLayout> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/home');
          },
          child: Text(
            'Watchdog',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w300),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 0),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            shadowColor: Colors.transparent,
          ),
        ),
      ),
      body: Padding(padding: const EdgeInsets.all(16.0), child: widget.child),
      drawer: Drawer(
        child: Stack(
          children: [
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
                child: SvgPicture.asset(
                  'assets/images/logo_berek_biale.svg',
                  alignment: const Alignment(-0.85, 0),
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 60),
                          padding: EdgeInsets.all(16),
                          child: Stack(
                            // alignment: Alignment.center,
                            children: [
                              Text(
                                'Watchdog',
                                style: TextStyle(
                                  fontSize: 45,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w100,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListTile(
                          title: Text("Strona główna"),
                          onTap: () {
                            Navigator.pushNamed(context, '/home');
                          },
                        ),
                        Divider(height: 0, thickness: 1, color: Colors.grey),
                        ListTile(
                          title: Text("Urządzenia"),
                          onTap: () {
                            Navigator.pushNamed(context, '/devices');
                          },
                        ),
                        Divider(height: 0, thickness: 1, color: Colors.grey),
                        ListTile(
                          title: Text("Powiadomienia"),
                          onTap: () {
                            Navigator.pushNamed(context, '/notifications');
                          },
                        ),
                        Divider(height: 0, thickness: 1, color: Colors.grey),
                        ListTile(
                          title: Text("Zweryfikowani domownicy"),
                          onTap: () {
                            Navigator.pushNamed(context, '/verified_users');
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text("Wyloguj"),
                      onTap: () => AppLayout.logoutUser(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
