# Contributing

## Prerequisites

- Dart SDK 3.10 or newer
- Flutter 3.38 or newer for Flutter packages, examples, and the DevTools
  extension package
- Melos 7.x via `dart run melos ...`

## Workspace Setup

Bootstrap the workspace from the repository root:

```bash
dart pub get
dart run melos bootstrap
```

The root `pubspec.yaml` is the source of truth for the Dart workspace and Melos
configuration.

## Common Commands

Run analysis:

```bash
dart run melos run analyze
```

Run all tests:

```bash
dart run melos run test
```

Run Dart-only tests:

```bash
dart run melos run test:dart
```

Run Flutter tests:

```bash
dart run melos run test:flutter
```

Format all workspace members:

```bash
dart run melos run format
```

Validate package publish surfaces without uploading:

```bash
dart run melos run publish:dry-run
```

## Code Style

- Keep changes focused and avoid unrelated refactors.
- Preserve existing public APIs unless the task explicitly requires an API change.
- Add tests for behavior changes.
- Update README and changelog files when public behavior changes.
- Do not commit temporary overrides or generated workspace artifacts.

## Pull Requests

Before opening a pull request, ensure the following:

- `dart run melos run analyze` passes
- `dart run melos run test` passes
- relevant `publish --dry-run` checks pass when package metadata, README, or
  examples changed
- `CHANGELOG.md` is updated when behavior or API changed

PRs should explain:

- what changed
- why it changed
- how it was validated
- whether there are API, docs, or release implications

## Reporting Issues

When filing an issue, include:

- affected package name and version
- Dart and Flutter SDK versions
- operating system
- reproduction steps
- expected behavior
- actual behavior
- logs, screenshots, or stack traces when relevant