import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_nav.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start a 5 second timer to simulate splash screen delay
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeNav()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensuring the splash covers the entire screen including status bar
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.expand(
          child: Image.asset(
            'assets/splash_bg.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
