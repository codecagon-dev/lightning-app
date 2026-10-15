# API integration

[Back to README](../README.md)

Backend repository: [Lightning API](https://github.com/codecagon-dev/lightning-api).
The backend repository contains the full API reference and setup instructions.

The frontend expects these endpoints, authenticated with a session cookie where
required:

| Method | Endpoint | Purpose |
| --- | --- | --- |
| POST | `/auth/register` | Register and sign in; 201 with user and session cookie |
| POST | `/auth/login` | Sign in; 200 with user and session cookie |
| GET | `/auth/me` | Validate the current session |
| POST | `/auth/logout` | End the session; 204 |
| GET | `/computers` | List devices; 200 with `{ "computers": [...] }` |
| POST | `/computers` | Register a device; 201 with `{ "computer": ... }` |
| PATCH | `/computers/:id` | Update changed fields; 200 with `{ "computer": ... }` |
| DELETE | `/computers/:id` | Delete a registration; 204 |
| POST | `/computers/:id/on` | Send WOL; 202 with `{ "ok": true }` |
| POST | `/computers/:id/off` | Request shutdown; 202 with `{ "ok": true }` |
| POST | `/computers/:id/check-ssh` | Check TCP/SSH with an empty body; 200 with diagnosis |
| WS | `/ws/computers` | Receive owner-scoped snapshots and status updates |

`ApiService` handles JSON, cookies, timeouts, and HTTP errors. `AuthService` manages
authentication, while `UserSession` holds the current user. `ApiDeviceRepository`
implements device operations and owns its live event source. HTTP and WebSocket
requests share the same cookie jar; session tokens are not placed in URLs.

`DeviceRepository` provides the base device operations. `EditableDeviceRepository`,
`SshCheckRepository`, and `LiveDeviceRepository` add editing, diagnostics, and live
updates. A repository can be injected into `LightningApp(repository: ...)` for
previews or tests. A caller-created `ApiDeviceRepository` must be disposed by that
caller. `MemoryDeviceRepository` is a preview/test implementation.

See [development setup](development.md) for API URLs and local HTTP configuration,
and [the user guide](usage.md) for session and device behavior.
