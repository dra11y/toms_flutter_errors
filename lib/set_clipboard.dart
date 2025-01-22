import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

Future<void> setClipboard(final SelectedContent? selectedContent) async {
  final text = selectedContent?.plainText;
  if (text != null) {
    if (kIsWeb || !Platform.isLinux) {
      await Clipboard.setData(ClipboardData(text: text));
      return;
    }

    try {
      final process = await Process.start('xsel', ['--input']);
      debugPrint('SET XSEL...');
      process.stdin.writeln(text);
      await process.stdin.close();
      if (exitCode == 0) {
        debugPrint('Clipboard set successfully with xsel: $text');
      } else {
        debugPrint('Failed to set clipboard with xsel. Exit code: $exitCode');
      }
    } catch (e) {
      debugPrint('Error using xsel: $e');
    }
  }
}
