# Field Sample Log

**Author:** Bhushan Gandhakte

Field Sample Log is an offline-first Flutter application for technicians
who collect water, soil, and air samples in the field. A technician can
record sample details without a live backend, keep those records on the
device, and queue samples for a simulated upload when needed.

The upload flow uses a fake service rather than a real server. This
makes it possible to exercise pending, uploading, uploaded, and failed
states during development without relying on a backend.

## How to run

### Requirements

-   Flutter **3.47.8 stable**
-   Dart **3.13.7** (included with the Flutter SDK above)
-   An Android emulator/device or an iOS simulator with its native
    toolchain configured
-   Xcode and CocoaPods for iOS builds

### Run the app

From the project root:

``` bash
flutter --version
flutter pub get
flutter run
```

To choose a connected device explicitly:

``` bash
flutter devices
flutter run -d <device-id>
```

### Run the automated checks

``` bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

The formatting command checks formatting without modifying files. If it
reports files that need formatting, apply formatting with
`dart format lib test`, then run the checks again.

### Development devices

The project README and development notes list these targets:

-   Android Emulator --- Pixel 9, API 36
-   Physical Android device --- OPPO A78 5G

## Architecture

The code is organized around three responsibilities: **presentation
(UI), state and application logic (Riverpod providers), and data access
(repository/database and upload service)**. The goal is to keep widgets
focused on displaying information and collecting user input, while
providers coordinate actions and the repository handles SQLite
operations.

### How data moves through the app

1.  A screen watches a Riverpod provider and renders its current state.
2.  When a user saves, edits, deletes, filters, or uploads a sample, the
    screen calls a provider/notifier action.
3.  The provider uses the repository to read or update the local SQLite
    database.
4.  The provider publishes the updated state, which causes listening
    widgets to rebuild.
5.  Upload actions go through `FakeUploadService`. Its result is
    translated into a sample status and saved locally.

This separation makes the flow easier to follow and gives validation and
state behavior places that can be tested without driving every
interaction through the UI.

### Folder layout

``` text
field_sample_log/
├── .github/
│   └── workflows/
│       └── flutter_ci.yml
├── android/                         # Android host project
├── ios/                             # iOS host project
├── lib/
│   ├── main.dart                    # App entry point, ProviderScope and MaterialApp
│   ├── framework/
│   │   ├── database/
│   │   │   └── app_database.dart    # SQLite database setup and schema
│   │   ├── model/
│   │   │   ├── sample_model.dart    # Sample data model and map conversion
│   │   │   └── sample_enums.dart    # Sample types and statuses
│   │   ├── provider/
│   │   │   ├── sample_providers.dart
│   │   │   ├── sample_form_provider.dart
│   │   │   ├── sample_list_filter_provider.dart
│   │   │   └── upload_providers.dart
│   │   ├── repository/
│   │   │   └── sample_repository.dart # SQLite CRUD operations
│   │   └── service/
│   │       └── fake_upload_service.dart # Simulated network behavior
│   ├── ui/
│   │   ├── sample/
│   │   │   ├── screens/
│   │   │   │   ├── sample_list_screen.dart
│   │   │   │   ├── sample_form_screen.dart
│   │   │   │   └── sample_detail_screen.dart
│   │   │   └── widgets/
│   │   │       ├── sample_card.dart
│   │   │       └── sample_status_chip.dart
│   │   └── utils/
│   │       ├── app_constants/
│   │       │   └── app_constants.dart
│   │       ├── theme/
│   │       │   ├── app_theme.dart
│   │       │   ├── app_colors.dart
│   │       │   └── app_spacing.dart
│   │       └── widgets/
│   │           ├── common_icon.dart
│   │           └── common_text.dart
└── test/
    └── framework/
        └── provider/
            ├── sample_form_provider_test.dart
            └── upload_providers_test.dart
```

**Layer responsibilities**

-   **`ui/` --- presentation:** Screens and reusable widgets display
    samples, form controls, status chips, and actions. The UI watches
    provider state and forwards user actions to notifiers.
-   **`framework/provider/` --- state and coordination:** Riverpod
    notifiers own form state, load and update the sample list, combine
    search/filter state, and coordinate upload status changes. This is
    the application logic layer between widgets and data sources.
-   **`framework/repository/` --- data access boundary:**
    `SampleRepository` provides CRUD methods so callers do not need to
    know SQLite query details.
-   **`framework/database/` --- persistence setup:** `AppDatabase`
    initializes the local database and defines the `samples` table.
-   **`framework/service/` --- external-service boundary:**
    `FakeUploadService` imitates a remote upload, allowing success and
    network-failure paths to be exercised without a real API.

The `framework` folder contains the data and application-state code; it
is not a Flutter UI folder. Keeping this distinction clear helps prevent
widgets from becoming responsible for SQL queries or upload rules.

### Riverpod state management

This project uses **`flutter_riverpod` 3.4.3** and the newer
`Notifier`/`NotifierProvider` API rather than the legacy
`StateNotifierProvider` approach.

-   `sampleListProvider` exposes the asynchronous list state and actions
    for loading, inserting, updating, and deleting samples.
-   `sampleFormProvider` is a family provider so the form can initialize
    from an existing sample when editing or use defaults when creating a
    new one. It is auto-disposed when no longer needed.
-   `searchQueryProvider` and `statusFilterProvider` hold the current
    list search and status filter.
-   `filteredSamplesProvider` derives the visible list from the saved
    samples and the current filters.
-   `uploadQueueProvider` tracks IDs currently being uploaded so a
    repeated tap for the same sample does not start a second upload
    while that ID is active.
-   `uploadServiceProvider` provides the fake upload service.

In simple terms, a notifier is the place where state changes and the
rules for those changes live. Widgets observe that state instead of
manually synchronizing multiple copies of the same data.

## Feature checklist

  --------------------------------------------------------------------------------------------------------
  Feature           Status            Main file/class                      Notes
  ----------------- ----------------- ------------------------------------ -------------------------------
  Sample list and   Done              `sample_list_screen.dart`            Displays saved samples and an
  empty state                                                              empty state when the database
                                                                           has no records.

  Newest-first      Done              `sample_repository.dart`             Queries by
  ordering                                                                 `collected_at DESC, id DESC`.

  Status chips      Done              `sample_status_chip.dart`            Shows the current sample status
                                                                           with a visual status indicator.

  Create and edit   Done              `sample_form_screen.dart`,           Supports site, type, collection
  samples                             `sample_form_provider.dart`          date/time, optional depth,
                                                                           conditional pH, and notes.

  Site-name         Done              `sample_form_provider.dart`          Requires a trimmed name between
  validation                                                               2 and 60 characters.

  Depth validation  Done              `sample_form_provider.dart`          Optional; if supplied, it must
                                                                           be numeric, between 0 and 100,
                                                                           and have at most two decimal
                                                                           places.

  Water pH          Done              `sample_form_provider.dart`          Required only for Water;
  validation                                                               validates the 0--14 range and
                                                                           at most two decimal places.

  Unsaved-changes   Done              `sample_form_screen.dart`            Uses `PopScope` and a
  confirmation                                                             confirmation dialog before
                                                                           discarding changes.

  Local persistence Done              `app_database.dart`,                 Stores samples in SQLite on the
                                      `sample_repository.dart`             device.

  Search and status Done              `sample_list_filter_provider.dart`   Derives the visible list from
  filter                                                                   search text and selected
                                                                           status.

  Pending-upload    Done              `sample_list_screen.dart`            Shows the number of
  count and Upload                                                         pending/failed samples and
  All action                                                               offers a bulk-upload action
                                                                           when needed.

  Simulated upload  Done              `fake_upload_service.dart`,          Fake service delays, can fail,
  with receipt                        `upload_providers.dart`              and returns a receipt on
                                                                           success.

  Failed state and  Done              `upload_providers.dart`,             Failed uploads are marked
  retry path                          `sample_detail_screen.dart`          failed and can be retried from
                                                                           the detail view.

  Duplicate active  Done              `upload_providers.dart`              Tracks active sample IDs in a
  upload guard                                                             set and removes them in
                                                                           `finally`.

  Recover samples   Done              `sample_providers.dart`              On list load, records left in
  left in Uploading                                                        `uploading` are reset to
                                                                           `pending`.

  Prevent deletion  Done              `sample_detail_screen.dart`          The delete action is not shown
  of uploaded                                                              for uploaded samples.
  samples                                                                  

  Automated tests   Partly done       `test/framework/provider/`           Form validation and
                                                                           upload-queue behavior have
                                                                           tests; more integration and UI
                                                                           tests would strengthen
                                                                           coverage.

  GitHub Actions CI Done              `.github/workflows/flutter_ci.yml`   Runs formatting validation,
                                                                           `flutter analyze`, and
                                                                           `flutter test` on pushes and
                                                                           pull requests targeting `main`.

  Dark theme        Done              `app_theme.dart`, `main.dart`        Light and dark Material 3
                                                                           themes are configured; the
                                                                           system setting selects the
                                                                           theme.

  CSV export /      Not done          ---                                  Not implemented in this
  settings screen                                                          version.
  --------------------------------------------------------------------------------------------------------

## Hard parts and implementation decisions

### 1. Preventing repeated upload taps

`UploadQueueNotifier` maintains a `Set<int>` of sample IDs currently
being uploaded. Before it begins, `uploadSample()` checks that the
sample has a database ID and is not already active. It adds the ID to
the set, changes the persisted sample status to `uploading`, and then
calls the fake service. The ID is removed in a `finally` block so it is
released after either success or failure.

This guard protects against duplicate simultaneous requests for the same
sample within the current app process. It is an in-memory guard, not a
distributed lock.

### 2. Simulating network errors and retrying

`FakeUploadService` waits approximately two seconds and throws a
`NetworkException` on every third call. Otherwise, it creates a receipt
ID. During a single service instance's lifetime, it remembers successful
receipts by sample ID and returns the same receipt for repeated
successful uploads of that sample.

`UploadQueueNotifier` translates a successful response into `uploaded`
plus a receipt ID. If the service throws, the sample is marked `failed`.
The detail screen exposes the upload action for samples that are not
already uploaded, allowing a failed sample to be tried again.

The fake service is intentionally in-memory: its call counter and
receipt map do not survive an app restart. This models the assignment's
fake-service behavior, not a durable server-side idempotency guarantee.

### 3. Recovering after an interrupted upload

An upload changes the stored status to `uploading` before waiting for
the service. If the process is killed at that point, the database can
retain that status. When `SampleListNotifier.loadSamples()` runs at
startup, it looks for records with `uploading`, changes them back to
`pending`, persists those changes, and reloads the list. This avoids
leaving a sample permanently stuck in the in-progress state after a
restart.

### 4. Conditional pH validation

`SampleFormNotifier.validatePh()` returns no validation error when the
selected type is not Water. For Water samples, pH is required, must
parse as a number, must be within 0--14, and may contain no more than
two decimal places. The form hides the pH input for Soil and Air and
clears the pH controller when the user changes away from Water.

Keeping the rule in the form notifier means validation is not dependent
only on whether a field happens to be visible.

### 5. Local persistence

`SampleRepository` wraps the SQLite queries used to read, insert,
update, and delete records. The model converts between `SampleModel`
objects and database maps. Collection timestamps are stored as ISO 8601
strings and enum values as strings, making them straightforward to
reconstruct when rows are read.

SQLite makes records available locally without requiring a server
connection. Riverpod state is updated after repository operations so the
list and detail views can react to changes.

### 6. Keeping UI and state responsibilities clear

The screens use Riverpod's `ref.watch` to observe state and `ref.read`
to call notifier actions. Filtering is composed in
`sample_list_filter_provider.dart`, instead of having every screen
independently implement search and status matching. Database queries
live in the repository, while the fake network behavior lives in its
service class.

### 7. Learning the current Riverpod API

I had previously worked with Riverpod's legacy `StateNotifier` pattern.
For this project, I reviewed the current `flutter_riverpod` API and used
`NotifierProvider`, `NotifierProvider.autoDispose.family`, `Provider`,
and derived providers instead. This helped me understand how to
initialize family-based form state, expose actions through a notifier,
dispose short-lived state, and let widgets react to provider updates.

## Cases checked during development

  -----------------------------------------------------------------------
  Scenario                            Expected/observed behavior
  ----------------------------------- -----------------------------------
  Create a sample                     The saved sample appears in the
                                      list with its selected status.

  Enter a one-character site name     Validation rejects the value; names
                                      must be 2--60 characters.

  Enter depth outside 0--100          Validation displays a range error.

  Enter more than two decimal places  Validation rejects the value.
  for depth                           

  Create a Water sample without pH    Validation requires pH.

  Create a Soil or Air sample without pH validation is skipped and the
  pH                                  field is hidden.

  Enter pH outside 0--14              Validation rejects the value.

  Navigate away after editing form    An unsaved-changes dialog offers
  fields                              Cancel or Discard.

  Search by site name / choose a      The displayed list is filtered.
  status                              

  Upload a sample                     It moves through uploading to
                                      uploaded or failed, depending on
                                      the fake service result.

  Retry a failed sample               The upload action can be invoked
                                      again.

  Start another upload for the same   The active-ID guard prevents a
  ID while it is active               second concurrent attempt for that
                                      ID.

  Restart after a sample was left     Loading the list resets that record
  uploading                           to pending.

  View an uploaded sample             Receipt information is shown when
                                      present, and delete is unavailable.
  -----------------------------------------------------------------------

## Tests

Run all automated tests with:

``` bash
flutter test
```

The current test suite contains:

-   **Form-provider tests** for site-name boundaries, optional depth and
    its range/decimal rules, Water-only pH validation, and dirty-state
    tracking.
-   **Upload-queue test** checking that a sample ID is added to the
    active queue while the fake upload is running and removed when the
    operation completes.

The upload test uses the real fake service's delay. The test suite is a
useful starting point, but it does not yet provide comprehensive widget,
database-repository, failure/retry, or app-restart integration coverage.
Those would be valuable additions.

## Change request

No separate external change request was provided for this implementation
milestone.

## Not finished / known limitations

-   CSV export and a settings screen are not implemented.
-   Automated coverage is focused on form validation and basic
    upload-queue state; broader UI and integration tests remain useful.
-   The upload service is a simulation, not a real API integration.
-   The fake service's receipt memory resets when its provider/service
    instance is recreated, as intended for the simulated service.

## Assumptions and decisions

-   **Riverpod 3:** state is implemented with `Notifier`-based providers
    rather than the legacy `StateNotifierProvider` pattern.
-   **Fake uploads:** a delay, periodic simulated network failure, and
    session-scoped receipt map make the upload lifecycle testable
    without a server.

## How I used AI

I used AI as a learning and review partner throughout development,
rather than relying on it only to generate code.

-   **Architecture discussions with ChatGPT:** I discussed how to divide
    responsibilities between the UI, Riverpod state layer, repository,
    SQLite database, and fake upload service. Those discussions helped
    me think through where validation, persistence, and upload-state
    transitions should live.
-   **Code review and debugging:** I used AI to review implementation
    choices, reason through edge cases, interpret errors, and identify
    areas that needed clearer separation or safer state handling. I then
    checked the suggestions against the actual project and local
    analyzer/test results.
-   **Learning modern Riverpod:** I had used Riverpod's legacy APIs
    before, so I used AI discussions to understand the current
    `flutter_riverpod` approach---especially `Notifier`,
    `NotifierProvider`, family providers, auto-disposal, and derived
    state. This was an opportunity to learn the current API instead of
    carrying forward an older pattern by habit.
-   **Valuable implementation insights:** The discussions highlighted
    the importance of guarding duplicate uploads, recovering persisted
    `uploading` states after a restart, keeping database access in the
    repository, and testing form rules separately from the UI.
-   **Validation remains my responsibility:** AI suggestions were
    treated as guidance. I ran formatting, `flutter analyze`, and
    `flutter test` locally and used their results to check the
    implementation. 

## Time spent

Approximate development time recorded during the project:

  Part                                                   Time
  ---------------------------------- ------------------------
  Initial setup and baseline                       60 minutes
  Models, database, and repository                 60 minutes
  Riverpod state and notifiers                     90 minutes
  Form UI and validation                           90 minutes
  Detail views and filters                         60 minutes
  Upload mechanics and recovery                    120 minutes
  Testing and documentation                        90 minutes
  **Total**                            **9 hours 30 minutes**
