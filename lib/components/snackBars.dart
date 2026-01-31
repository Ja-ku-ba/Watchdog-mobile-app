import 'package:flutter/material.dart';


void showSnackBar(BuildContext context, String message, {Color color = Colors.red}) {

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: color,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(message)),
          Builder(
            builder: (builderContext) => IconButton(
              onPressed: () {
                ScaffoldMessenger.of(builderContext).hideCurrentSnackBar();
              },
              icon: Icon(Icons.close, color: Colors.white),
            ),
          )
        ],
      ),
    ),
  );
}