import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),

        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
    );
  }
}
