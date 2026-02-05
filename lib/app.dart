import 'package:flutter/cupertino.dart';
import 'features/auth/ui/signup_screen.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      theme: CupertinoThemeData(primaryColor: CupertinoColors.activeBlue),
      home: SignUpScreen(), // Starting point for Sprint 1
    );
  }
}
