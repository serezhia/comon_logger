## Unreleased

- Logger levels are hierarchical: a logger without its own level inherits its parent's, so `Logger.root.level` now applies to child loggers. Assign `null` to inherit again. Default behaviour is unchanged while the root stays at `FINEST`.
- Added `Logger.isLoggable(level)` to guard expensive messages.
- Added record transformers (`LogRecordTransformer`, `Logger.addTransformer` / `removeTransformer`) that rewrite or drop records before handlers and `onRecord` see them.
- Added `RedactLogTransformer` to redact `extra` keys and cut long strings.
- Added `Logger.reset()` for test isolation.

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

