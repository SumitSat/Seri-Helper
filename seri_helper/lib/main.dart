import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_providers.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

import 'theme/localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const SeriHelperApp());
}

class SeriHelperApp extends StatelessWidget {
  const SeriHelperApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => RearingContextProvider()),
        ChangeNotifierProvider(create: (_) => LeafScanProvider()),
        ChangeNotifierProvider(create: (_) => SoilDataProvider()),
      ],
      child: MaterialApp(
        title: 'Seri-Helper',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const SplashScreen(),
      ),
    );
  }
}
