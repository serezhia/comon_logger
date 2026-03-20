## 0.1.2

- Moved the package into the shared `packages/` workspace layout and refreshed package metadata for the unified monorepo structure.
- Added regression coverage for formatter add-ons and chunked console output while keeping validation green in the new workspace setup.

## 0.1.1

- ConsoleLogHandler now supports formatter add-ons via a `formatters` list.
- Console output now splits long lines to avoid Flutter/logcat truncation.
- Maintenance release for workspace version alignment.

## 0.1.0

- Initial release of comon_logger.
- A modular, extensible logging library for Dart.

