import 'package:flutter/material.dart';
import 'package:watchdog/services/auth.dart';
import 'package:watchdog/components/snackBars.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _passwordHidden = false;
  @override
  void initState() {
    _passwordHidden = false;
  }
  void _showPassword() {
    setState(() {
      _passwordHidden = !_passwordHidden;
    });
  }

  void loginUser(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final username = usernameController.text.trim();

    if (email.isEmpty | password.isEmpty | username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Wypełnij wszystkie pola formularza')),
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
      return;
    }

    final emailRegex = RegExp(
      r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
    );

    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Niepoprawny format adresu e-mail')),
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
      return;
    }

    final (success: status, error: message) = await AuthService.register(email, password, username);
    if (status) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if(!status && message != null) {
      showErrorSnackBar(context, message);
    } else {
      showErrorSnackBar(context, "Coś ewidentnie, poszło nie tak");
    }
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
                TextField(
                  keyboardType: TextInputType.emailAddress,
                  controller: usernameController,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    hintText: 'Nazwa użytkownika',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
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
                SizedBox(height: 15),
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
                  child: Text('Zarejestruj'),
                  onPressed: () => loginUser(context),
                ),
                SizedBox(height: 25),
                Text("Masz już konto?"),
                TextButton(onPressed: () => {
                    Navigator.of(context).pushReplacementNamed('/login')
                  },
                  child: Text("Zaloguj się")
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
