import 'package:flutter/material.dart';
import 'package:toms_flutter_errors/toms_flutter_errors.dart';

import 'set_clipboard.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  static ErrorView from(Object error, StackTrace stackTrace) =>
      ErrorView(error: error, stackTrace: stackTrace);

  @override
  Widget build(BuildContext context) {
    final textStyle = DefaultTextStyle.of(context).style;
    final fontSize = (textStyle.fontSize ?? 14.0) * 2;

    return SizedBox.expand(
      child: SelectionArea(
        onSelectionChanged: setClipboard,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(fontSize),
          children: [
            Text('ERROR VIEW'),
            Text(
              error.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize * 2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 20),
            for (final line in stackTrace.toString().split('\n'))
              Builder(builder: (context) {
                final isApp =
                    line.contains(TomsFlutterErrors.instance.ourCodePath);
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    line.trim(),
                    style: TextStyle(
                      fontSize: isApp ? fontSize * 1.5 : fontSize,
                      color: isApp ? Colors.yellow : Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
