import 'package:flutter/material.dart';

import 'error_view.dart';

class CustomErrorWidget extends StatelessWidget {
  const CustomErrorWidget(
    this.details, {
    super.key,
  });

  final FlutterErrorDetails details;

  static void install() {
    ErrorWidget.builder = (details) => CustomErrorWidget(details);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: const Color.fromARGB(255, 160, 255, 255),
        ),
        darkTheme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color.fromARGB(255, 80, 0, 0),
        ),
        builder: (context, child) => Scaffold(
          body: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: ErrorView(
              error: details.exception,
              stackTrace: details.stack ?? StackTrace.current,
            ),
          ),
        ),
      );
}
