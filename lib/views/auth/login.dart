import 'package:flutter/material.dart';
import 'package:watchdog/services/auth.dart';
import 'package:watchdog/components/snackBars.dart';


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _passwordHidden = false;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _passwordHidden = false;
      _isLoading = false;
  }

  void _showPassword() {
    setState(() {
      _passwordHidden = !_passwordHidden;
    });
  }

  void loginUser(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showSnackBar(context, "Wypełnij wszystkie pola formularza");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final emailRegex = RegExp(
      r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
    );

    if (!emailRegex.hasMatch(email)) {
      showSnackBar(context, "Niepoprawny format adresu e-mail");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    final (success: status, error: message) = await AuthService.login(email, password);
    if (status) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if(message != null) {
      showSnackBar(context, message);
    } else {
      showSnackBar(context, "Coś ewidentnie, poszło nie tak");
    }
    setState(() {
      _isLoading = false;
    });
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
                  child: _isLoading ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)
                  ) : Text('Zaloguj'),
                  onPressed: () => _isLoading ? null : loginUser(context),
                ),
                SizedBox(height: 25),
                Text("Nie masz konta?"),
                TextButton(onPressed: () => {
                    _isLoading ? null : Navigator.of(context).pushReplacementNamed('/register')
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
