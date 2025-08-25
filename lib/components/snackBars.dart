import 'package:flutter/material.dart';

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.red,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(message)),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            icon: Icon(Icons.close, color: Colors.white),
          )
        ],
      ),
    ),
  );
}


// class CustomButton extends StatelessWidget {
//   final String label;
//   final VoidCallback onPressed;
//
//   const CustomButton({
//     Key? key,
//     required this.label,
//     required this.onPressed,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         backgroundColor: Colors.red,
//         content: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Expanded(child: Text('Niepoprawny format adresu e-mail')),
//             IconButton(
//                 onPressed: () {
//                   ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                 },
//                 icon: Icon(
//                   Icons.close,
//                   color: Colors.white,
//                 )
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }