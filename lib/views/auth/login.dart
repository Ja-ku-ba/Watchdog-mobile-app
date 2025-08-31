import 'package:flutter/material.dart';
import 'package:watchdog/services/auth.dart';
import 'package:watchdog/components/snackBars.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  static Future<void> myPrinter() async {
    final prefs = await SharedPreferences.getInstance();
  }
  bool _passwordHidden = false;
  @override
  void initState() {
    _passwordHidden = false;
    myPrinter();
  }
  void _showPassword() {
    setState(() {
      _passwordHidden = !_passwordHidden;
    });
  }

  void loginUser(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty | password.isEmpty) {
      showErrorSnackBar(context, "Wypełnij wszystkie pola formularza");
      return;
    }

    final emailRegex = RegExp(
      r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
    );

    if (!emailRegex.hasMatch(email)) {
      showErrorSnackBar(context, "Niepoprawny format adresu e-mail");
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    final (success: status, error: message) = await AuthService.login(email, password);
    if (status) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if(message != null) {
      showErrorSnackBar(context, message);
    } else {
      showErrorSnackBar(context, "Coś ewidentnie, poszło nie tak");
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1000),
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  controller: emailController,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    hintText: 'email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 25),
                TextFormField(
                  obscureText: !_passwordHidden,
                  controller: passwordController,
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                      hintText: 'hasło',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                          onPressed: _showPassword,
                          icon: Icon(
                              _passwordHidden ? Icons.visibility : Icons.visibility_off
                          )
                      )
                  ),
                ),
                SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(200, 25),
                    padding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    )
                  ),
                  child: Text('Zaloguj'),
                  onPressed: () => loginUser(context),
                ),
                SizedBox(height: 25),
                Text("Nie masz konta?"),
                TextButton(onPressed: () => {
                    Navigator.of(context).pushReplacementNamed('/register')
                  },
                  child: Text("Zarejestruj się")
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
