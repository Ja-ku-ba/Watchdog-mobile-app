import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watchdog/services/auth.dart';

class AppLayout extends StatelessWidget {
  final Widget child;

  const AppLayout({required this.child, super.key});

  static Future<void> logoutUser(context) async {
    AuthService.logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  static void showMesenger(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Funkcja jeszcze nie gotowa, aplikacja w tym momencie skupia się na stramingu')),
            IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                )
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/home'),
          child: Text(
            'Watchdog',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w300
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 0),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            shadowColor: Colors.transparent,
          ),
        )
      ),
      body: Padding(padding: const EdgeInsets.all(16.0), child: child),
      drawer: Drawer(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      // padding: EdgeInsets.zero,
                      children: [
                        DrawerHeader(
                          child: Text(
                            "Watchdog, Twój system monirowania",
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
                          onTap: () => Navigator.pushNamed(context, '/home'),
                        ),
                        Divider(height: 0, thickness: 1, color: Colors.grey,),
                        ListTile(
                          title: Text("Profil"),
                          onTap:
                              () => showMesenger(context)
                              // () => Navigator.pushNamed(context, '/settings'),
                        ),
                        Divider(height: 0, thickness: 1, color: Colors.grey,),
                        ListTile(
                          title: Text("Ustawienia"),
                          onTap:
                            () => showMesenger(context)
                            // () => Navigator.pushNamed(context, '/settings'),
                        ),
                        Divider(height: 0, thickness: 1, color: Colors.grey,),
                        ListTile(
                          title: Text("Urządzenia"),
                          onTap:
                              () => showMesenger(context)
                              // () => Navigator.pushNamed(context, '/settings'),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text("Wyloguj"),
                      onTap: () => logoutUser(context),
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
