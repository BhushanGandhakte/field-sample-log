# Field Sample Log

Starting point for the Field Sample Log practical project. The current app is a runnable empty-state scaffold; the assignment workflows are not implemented yet.

## How to run

- Flutter / Dart requirement recorded in the project lockfile: Flutter `>=3.44.0`, Dart `>=3.13.7 <4.0.0`.
- Commands: `flutter pub get`, `flutter run`.
- Devices / emulators tested: none recorded yet.

## Architecture

The familiar `ui/` and `framework/` split is retained. `ui/` contains presentation code and compatibility exports. `framework/model/` defines sample data and domain enums; `framework/database/` owns SQLite setup; `framework/repository/` centralizes local persistence; `framework/service/` is the upload boundary; and `framework/controller/` exposes Riverpod dependencies.

```text
lib/
├── main.dart
├── ui/
│   ├── sample/
│   └── utils/
└── framework/
    ├── controller/
    ├── database/
    ├── model/
    ├── repository/
    └── service/
```

## Feature checklist

| Item | Status | File / class | Note |
| --- | --- | --- | --- |
| Sample list with status chips, newest first, empty state | Partly | `SampleListScreen`, `SampleRepository` | Empty state exists; database ordering is newest first, but list binding and chips remain. |
| Add / edit form with all fields and inline validation | Not done | — | — |
| pH required for Water only | Not done | — | — |
| Unsaved changes warning | Not done | — | — |
| Local database: data and statuses survive a kill | Partly | `AppDatabase`, `SampleRepository` | Schema and persistence methods exist; no end-to-end restart verification. |
| Upload one sample (FakeUploadService) | Partly | `FakeUploadService` | Service boundary stub exists; no UI/state workflow. |
| Upload all pending | Not done | — | — |
| Failed upload shows Upload failed with Retry | Not done | — | — |
| Double taps do not send two uploads | Not done | — | — |
| Kill during upload: not stuck in Uploading | Not done | — | — |
| Delete with confirmation (not for uploaded samples) | Not done | `SampleRepository` | Repository delete method exists; policy and confirmation UI do not. |
| Search by site and filter by status | Not done | — | — |
| Expected: at least three automated tests | Not done | `test/widget_test.dart` | One empty-state widget test. |
| Expected: GitHub Actions (flutter analyze, flutter test) | Not done | — | — |
| Expected: pending count at the top | Not done | — | — |
| Optional: CSV export / settings | Not done | — | — |

## How I handled the hard parts

The assignment behaviors are not implemented in this foundation. The database schema persists sample fields and status values, and repository methods provide ordered reads, saves, and deletes. Upload retry behavior, conditional pH validation, concurrency control, and recovery after interruption still need implementation.

## Cases I tested

| Case | What I saw |
| --- | --- |
| Not run in this environment | Flutter tooling could not be verified because its SDK cache attempted a write outside the workspace. |

## The change request

Retain the familiar folders, establish model/database/repository/service/provider responsibilities, keep Riverpod and SQLite dependencies, and replace the counter demo with a minimal Field Sample Log scaffold.

## Tests

`flutter test` runs the current empty-state widget test. `flutter analyze` checks the Dart sources. Neither has been run successfully in this environment.

## Not finished

Sample creation and editing, validation, upload orchestration/retry, upload locking/recovery, searchable/filterable list UI, deletion policy, pending count, broader automated tests, CI, and screenshots.

## Assumptions and decisions

The current lockfile records Dart `>=3.13.7 <4.0.0` and Flutter `>=3.44.0`; the existing `pubspec.yaml` Dart constraint was retained. `flutter_riverpod`, `sqflite`, and `path` remain dependencies.

## How I used AI

AI-assisted edits established the project structure and scaffold. Review the source and run the commands above in the target Flutter environment before building assignment features on top.

## Time spent

| Part | Time |
| --- | --- |
| Foundation changes | — |

