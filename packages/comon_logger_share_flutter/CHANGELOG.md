## Unreleased

- `ShareLogsAction(logFiles: ...)` adds a "Share log files" option that shares the log files on disk through the share sheet, skipping missing files.
- Added `ShareLogsStrings` so the button and sheet text can be translated; English stays the default.
- `share_plus` constraint widened to `>=12.0.0 <14.0.0`, so apps already on share_plus 13 can depend on this package.

## 0.1.2

- Moved the package into the shared `packages/` workspace layout and refreshed repository metadata and documentation links.
- Revalidated the share action package against the unified Flutter workspace toolchain.

## 0.1.1

- Maintenance release for workspace version alignment.

## 0.1.0

- Initial release of comon_logger_share_flutter.
- Share/export action for comon_logger log viewer.

