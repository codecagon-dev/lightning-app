# Lightning

**Vibe-coded app:** Built with substantial assistance from AI coding tools.
Currently under active development and personally tested by me (Jelte).
Features and behavior may change; production readiness has not been established.

Lightning is a Flutter app for managing your own computers on a local network.
Register devices, wake them with Wake-on-LAN, shut them down over SSH, and follow
their status through the Lightning API.

## Platforms and features

The app targets **Linux and Android**. It includes:

- Account registration, login, and logout using API session cookies.
- Device registration, editing, deletion, and optional device colors.
- Wake-on-LAN and SSH shutdown, with confirmation before shutdown.
- Live device updates through WebSockets, with automatic reconnection.
- Separate TCP reachability and SSH authentication diagnostics.
- A manual SSH check with progress and error feedback.
- English and Dutch, with a saved language preference.
- A responsive layout for phone and desktop screens.

The backend is a separate application: [Lightning API](https://github.com/codecagon-dev/lightning-api). It stores accounts, device registrations,
and SSH credentials, and performs the actual network and power operations.
This repository contains the Flutter frontend.

## Quick start

Install Flutter with a Dart SDK compatible with `pubspec.yaml` (`^3.13.2`) and
start a compatible Lightning API. Then:

```sh
flutter pub get
cp .env.example .env
# Set your API URLs in .env.
flutter run -d linux
# For Android, use flutter run -d <device-id>.
```

The default API URL is `http://localhost:3000`; Android emulators use
`http://10.0.2.2:3000`. The [Lightning API backend](https://github.com/codecagon-dev/lightning-api) is a
separate application and must be running.
See the [development guide](docs/development.md) for platform setup, configuration,
and local HTTP cookies. The bundled `.env` is public app configuration; keep
secrets out of it.

## Documentation

- [User guide](docs/usage.md): accounts, sessions, device editing, power actions,
  and SSH diagnostics.
- [Development guide](docs/development.md): setup, Android networking, debug logs,
  project structure, and verification.
- [API integration](docs/api-integration.md): expected endpoints, services,
  repositories, and dependency ownership.

## Checks

```sh
flutter analyze
flutter test
```

Tests use controlled transports. Real hardware and platform testing by the
maintainer is ongoing.

## License

The application code is available under the [MIT License](LICENSE).
Third-party components retain their own licenses. The bundled wordmark font is
derived from Roboto; its license is included in
[assets/fonts/Roboto_LICENSE.txt](assets/fonts/Roboto_LICENSE.txt).
