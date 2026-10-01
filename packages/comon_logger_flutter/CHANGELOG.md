## Unreleased

- Added `ComonLoggerStrings` and `ComonLoggerStringsScope`: every visible text of the viewer (screen, filter panel, record card, import dialog) can be translated. Pass `strings:` to `ComonLoggerScreen` or provide a scope; defaults stay English.
- `HistoryLogHandler` drops the oldest record in O(1) once `maxHistory` is reached.
- An open `ComonLoggerScreen` now keeps at most `maxHistory` records instead of growing for as long as it stays open.

## 0.1.2

- Moved the package into the shared `packages/` workspace layout and refreshed repository metadata and documentation links.
- Preserved the newer viewer ordering and viewport behavior while validating the package against the unified workspace toolchain.

## 0.1.1

- Log viewer now opens at the top while showing newest logs first by default.
- Incoming logs no longer shift the current viewport when auto-scroll is off.
- Maintenance release for workspace version alignment.

## 0.1.0

- Initial release of comon_logger_flutter.
- Flutter UI for comon_logger.

