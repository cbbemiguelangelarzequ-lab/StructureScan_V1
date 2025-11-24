// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:structurescan_app/constants.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAzulPrincipalOscuro,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/structurescan_logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            Text(
              'StructureScan',
              style: kTituloPrincipalStyle.copyWith(fontSize: 32.0),
            ),
            const SizedBox(height: 10),
            Text(
              'Tu aliado para la seguridad estructural',
              style: kBodyTextStyle.copyWith(color: kBlanco, fontSize: 16.0),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kNaranjaAcento),
            ),
          ],
        ),
      ),
    );
  }
}