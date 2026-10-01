## Unreleased

- `FileLogHandler` batches writes instead of a synchronous disk write per record. Pending lines are written after `flushInterval` (default 500 ms), at `maxBufferBytes` (default 64 KB), immediately for records at `flushLevel` (default `SEVERE`), and on `flush` / `close`. Rotation happens at the same line boundaries as before. `flushInterval: Duration.zero` restores per-record writes.

## 0.1.2

- Moved the package into the shared `packages/` workspace layout and refreshed repository metadata and documentation links.
- Kept file handler exports and analyzer output clean after the monorepo restructuring.

## 0.1.1

- Maintenance release for workspace version alignment.

## 0.1.0

- Initial release of comon_logger_file.
- File-based log handler for comon_logger.

