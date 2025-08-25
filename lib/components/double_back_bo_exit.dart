import 'package:flutter/material.dart';

class DoubleBackToExit extends StatefulWidget {
  final Widget child;
  const DoubleBackToExit({super.key, required this.child});

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastPressed;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();

        if (_lastPressed == null || now.difference(_lastPressed!) > const Duration(seconds: 2)) {
          _lastPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Naciśnij ponownie, aby wyjść')),
          );
          return false;
        }
        return true;
      },
      child: widget.child,
    );
  }
}
