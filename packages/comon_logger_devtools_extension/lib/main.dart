import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'src/panel.dart';

void main() {
  runApp(const ComonLoggerDevToolsApp());
}

/// Entry point for the comon_logger DevTools extension.
class ComonLoggerDevToolsApp extends StatelessWidget {
  const ComonLoggerDevToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: ComonLoggerDevToolsPanel(),
    );
  }
}
