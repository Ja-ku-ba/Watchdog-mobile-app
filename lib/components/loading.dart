import 'package:flutter/material.dart';


class LoadingCircle extends StatelessWidget {
  final double size;
  const LoadingCircle({
    super.key,
    required this.size
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: Colors.red,
        )
      ),
    );
  }
}