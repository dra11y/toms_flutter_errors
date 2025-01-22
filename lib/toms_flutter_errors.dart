import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;

import 'custom_error_widget.dart';

final class TomsFlutterErrors {
  const TomsFlutterErrors._({
    required this.appName,
    required this.consoleWidth,
  });

  static late final TomsFlutterErrors instance;

  static void initialize({
    required String appName,
    required int consoleWidth,
  }) {
    instance = TomsFlutterErrors._(
      appName: appName,
      consoleWidth: consoleWidth,
    );

    _TomsLogger.initialize(maxLineWidth: consoleWidth);
    CustomErrorWidget.install();
  }

  final String appName;
  final int consoleWidth;

  // get terminal width dynamically?
  // https://medium.com/@tejainece/finding-size-of-terminal-in-dart-5f72e95215b8
  // main() {
  //   if (!stdout.hasTerminal) {
  //     print('Stdout not attached to a terminal! Exiting...');
  //     exit(0);
  //   }

  //   print('${stdout.terminalLines} x ${stdout.terminalColumns}');

  //   ProcessSignal.SIGWINCH.watch().listen((_) {
  //     print('${stdout.terminalLines} x ${stdout.terminalColumns}');
  //   });
  // }
}

final class _TomsLogger {
  const _TomsLogger();

  static void initialize({int maxLineWidth = 67}) {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.demangleStackTrace = stack_trace.Trace.from;

    final talker = TalkerFlutter.init(
      logger: TalkerLogger(
          settings: TalkerLoggerSettings(
        maxLineWidth: maxLineWidth,
      )),
    );
    final colorizer = _LogColorizer.standard(maxLineWidth: maxLineWidth);

    FlutterError.onError = (details) {
      final node = details.toDiagnosticsNode(style: DiagnosticsTreeStyle.error);
      final level = node.level.talkerLevel;
      if (level == null) {
        return;
      }
      final message = colorizer.colorize(node.toStringDeep(
          wrapWidth: 60,
          prefixLineOne: '${node.level.name.toUpperCase()}\n',
          prefixOtherLines: ''));

      talker.log(
        message,
        logLevel: level,
        exception: details.exception,
        stackTrace: details.stack,
      );
    };
  }
}

typedef _LogReplaceFn = ({
  AnsiPen Function()? color,
  String Function(Match)? replace
});

class _LogColorizer {
  final Map<RegExp, _LogReplaceFn> matchers;
  final int maxLineWidth;

  _LogColorizer._({
    required this.matchers,
    required this.maxLineWidth,
  });

  // Factory constructor with default matchers
  factory _LogColorizer.standard({required int maxLineWidth}) {
    return _LogColorizer._(matchers: {
      // RegExp(r'(?<=The relevant error-causing widget was:\n).*',
      RegExp(r'The relevant error-causing widget was:', multiLine: true): (
        color: () => AnsiPen()..yellow(),
        replace: null
      ),

      RegExp(r'(◢◤)+'): (
        color: null,
        replace: (match) => match.group(0)!._truncate(maxLineWidth - 1),
      ),

      // Match file paths (assuming they start with 'file:///')
      RegExp(r'.*(file:\/\/\/[^\s:]*unitymeet\/flutter_app\/)[^\s:]*'): (
        color: () => AnsiPen()..yellow(),
        replace: (match) {
          final line = match.group(0)!;
          final path = match.group(1);
          if (path == null) {
            return line;
          }
          return line.replaceFirst(path, ' ');
        },
      ),

      // Match constraint and size lines
      RegExp(r'^.*(?:constraints|size):.*$', multiLine: true): (
        color: () => AnsiPen()..red(bold: true),
        replace: null
      ),
    }, maxLineWidth: maxLineWidth);
  }

  // Process the message and apply colors
  String colorize(final String message) {
    String result = message;

    for (final entry in matchers.entries) {
      final pattern = entry.key;
      final colorFn = entry.value.color;
      final replaceFn = entry.value.replace;
      result = result.replaceAllMapped(pattern, (match) {
        String? matchedText = match.group(0);
        if (matchedText == null) return '';
        if (replaceFn != null) {
          matchedText = replaceFn(match);
        }
        if (colorFn == null) return matchedText;
        return colorFn().write(matchedText);
      });
    }

    return result;
  }
}

extension DiagnosticLevelExtension on DiagnosticLevel {
  LogLevel? get talkerLevel => switch (this) {
        DiagnosticLevel.hidden => null,
        DiagnosticLevel.fine => LogLevel.debug,
        DiagnosticLevel.debug => LogLevel.debug,
        DiagnosticLevel.info => LogLevel.info,
        DiagnosticLevel.warning => LogLevel.warning,
        DiagnosticLevel.hint => LogLevel.debug,
        DiagnosticLevel.summary => LogLevel.debug,
        DiagnosticLevel.error => LogLevel.error,
        DiagnosticLevel.off => null,
      };
}

extension _StringExtension on String {
  String _truncate(int maxlen, {bool dots = false}) =>
      length <= maxlen ? this : '${substring(0, maxlen)}${dots ? '...' : ''}';
}
