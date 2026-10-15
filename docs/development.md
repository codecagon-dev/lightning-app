# Development

[Back to README](../README.md)

## Setup

Install Flutter with a Dart SDK compatible with `pubspec.yaml` (`^3.13.2`), plus
the platform tooling needed for Linux or Android. Start a compatible Lightning
API, then run:

```sh
flutter pub get
cp .env.example .env
flutter run -d linux
# Or select a connected Android device:
flutter devices
flutter run -d <device-id>
```

Configure `.env` before starting the app:

```dotenv
API_BASE_URL=http://localhost:3000
ANDROID_API_BASE_URL=http://10.0.2.2:3000
API_DEBUG_LOGS=true
API_DEBUG_SENSITIVE=false
```

Linux uses `API_BASE_URL`. Android uses `ANDROID_API_BASE_URL` when set, otherwise
it falls back to `API_BASE_URL`. There is no `/api` prefix in the default setup.

In the standard Android emulator, `10.0.2.2` points to the development computer.
For a physical Android device connected over USB, you can use:

```sh
adb reverse tcp:3000 tcp:3000
```

Then set `ANDROID_API_BASE_URL=http://localhost:3000`.
Android permits cleartext HTTP for `localhost`, `127.0.0.1`, and `10.0.2.2`;
use HTTPS for other hosts.

The app bundles `.env` as an asset. **Do not put secrets in it.** Restart the app
after changing it. For local HTTP development, the backend must issue its session
cookie without `Secure`. Production should use HTTPS and Secure cookies.

## Development logs

Set `API_DEBUG_LOGS=true` to enable `[api]` logs in debug builds. They include
request timing, status codes, cookie handling, and authentication outcomes.

`API_DEBUG_SENSITIVE=true` additionally logs full response URLs, bodies, and
headers, including session cookies. Request bodies such as login passwords are
not logged. Keep this option off when sharing logs.

Both log modes are guarded by `kDebugMode` and emit nothing in release or profile
builds, regardless of the `.env` settings.

## Project structure

```text
lib/
├── main.dart          # Entry point and environment configuration
├── app.dart           # App composition, services, and session routing
├── config/            # Environment parsing
├── l10n/              # English and Dutch translations
├── models/            # Public devices, events, and request models
├── screens/           # Authentication, home, device forms, and settings
├── services/          # HTTP, cookies, authentication, repositories, WebSockets
├── settings/          # Language preferences
├── theme/             # Shared styling
├── validation/        # Authentication and device input validation
└── widgets/           # Shared widgets and wordmark
```

## Verification

```sh
flutter analyze
flutter test
```

Automated tests cover authentication, cookie handling, API contracts, device
forms, editing, live updates, and device actions using controlled transports.
They do not prove that real hardware wakes up or shuts down correctly.
The maintainer is currently testing the app manually; device, network, and
platform compatibility testing is ongoing.
