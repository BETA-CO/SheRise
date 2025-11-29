import "package:flutter/material.dart";

class MyGoogleSignInButton extends StatelessWidget {
  final void Function()? onTap;

  const MyGoogleSignInButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 243, 248),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        child: Image.asset("lib/assets/image.png", height: 40),
      ),
    );
  }
}
