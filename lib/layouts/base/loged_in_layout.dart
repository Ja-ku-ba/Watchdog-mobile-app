import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watchdog/services/auth.dart';

class AppLayout extends StatefulWidget {
  final Widget child;

  const AppLayout({required this.child, super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();

  static Future<void> logoutUser(context) async {
    AuthService.logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }
  static void showMesenger(BuildContext context) {

    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Funkcja niedostępna'),
            content: Text(
              'Funkcja jeszcze nie gotowa, aplikacja skupia się na streamingu',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
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
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        DrawerHeader(
                          child: Text(
                            "Watchdog",
                            style: TextStyle(
                              fontSize: 25,
                              shadows: [
                                Shadow(
                                  offset: Offset(10, 10),
                                  blurRadius: 0,
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ],
                            ),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
