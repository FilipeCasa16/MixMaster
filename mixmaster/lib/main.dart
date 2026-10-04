import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/main_shell.dart';

void main() => runApp(const MixMasterApp());

class MixMasterApp extends StatelessWidget {
  const MixMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MixMaster',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const MainShell(),
    );
  }
}
