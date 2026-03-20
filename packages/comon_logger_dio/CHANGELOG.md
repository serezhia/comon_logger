## 0.1.2

- Moved the package into the shared `packages/` workspace layout and refreshed repository metadata and README links.
- Locked in the HTTP console formatter defaults and tests so workspace validation matches the intended request and response rendering behavior.

## 0.1.1

- Added `HttpConsoleLogFormatter` for rich Dio console rendering.
- Added separate error visibility flags plus `showFullUrl` and `showQueryParams`.
- Console HTTP response bodies are no longer truncated by default.
- Added coverage for the non-truncating default behavior.

## 0.1.0

- Initial release of comon_logger_dio.
- Dio HTTP interceptor for comon_logger.

