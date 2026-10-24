import 'package:comon_logger/comon_logger.dart';
import 'package:sentry/sentry.dart';

/// Maps comon_logger levels to Sentry levels by value, so custom levels land
/// next to the predefined level below them.
SentryLevel mapLogLevelToSentryLevel(LogLevel level) {
  if (level >= LogLevel.SHOUT) {
    return SentryLevel.fatal;
  }
  if (level >= LogLevel.SEVERE) {
    return SentryLevel.error;
  }
  if (level >= LogLevel.WARNING) {
    return SentryLevel.warning;
  }
  if (level >= LogLevel.INFO) {
    return SentryLevel.info;
  }
  return SentryLevel.debug;
}
