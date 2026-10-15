# Using Lightning

[Back to README](../README.md)

## Accounts and sessions

Sign in with an account provided by your Lightning API administrator. The app
validates the email and requires an account password of 12–128 characters.
Passwords retain their spaces; email addresses are trimmed and lowercased.

The app keeps the signed-in user and its cookie jar **in memory for the current
app session only**. Closing the app requires signing in again. The cookie jar is
shared by HTTP requests and the WebSocket connection.

Logout in Settings calls `POST /auth/logout`, closes the live connection, and
clears the local session. If the request fails, the app still signs out locally
and reports that server-side logout could not be confirmed. A current-session
HTTP 401 returns the app to the login screen.

The language preference is stored locally using `shared_preferences`. Device
registrations are loaded from the backend; SSH credentials are not persisted by
the frontend or included in its public device model.

## Managing devices

Use the add button to register a computer. The form collects its name, operating
system, IPv4 address, MAC address, broadcast address, WOL and SSH ports, SSH
username, trusted host fingerprint, and either a password or private key. Private
keys can have a passphrase. Color is optional.

The fingerprint must include the `SHA256:` prefix. Obtain it from a trusted
console on the target computer. For example, on Linux:

```sh
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub -E sha256
```

Copy only the complete `SHA256:...` value. The backend's setup instructions cover
SSH access, shutdown permissions, and Wake-on-LAN configuration.

Tap a device card to view its public details. Use the pencil button to edit it.
Editing sends only changed fields with `PATCH /computers/:id`; selecting **No
color** sends `color: null`. Existing SSH credentials remain unchanged unless
**Replace SSH credentials** is enabled and replacement credentials are supplied.
Deleting a device asks for confirmation and removes its registration; it does
not shut down the physical computer.

**Wake up** requests a WOL packet. Acceptance confirms that the backend sent the
packet, not that the computer has finished starting. **Shut down** asks for
confirmation before requesting a real SSH shutdown. Power actions are not
automatically retried.

### Status and SSH checks

**Online**, **Offline**, and **Unknown** describe reachability of the configured
SSH TCP port. Online does not prove a successful SSH login or a fully started
computer.

SSH diagnostics distinguish an unchecked connection, a successful login, refused
authentication, a host key mismatch, an unreachable service, and a check error.
The card shows the last SSH check time and any relevant diagnosis; the successful
“SSH ready” label is omitted from the card. Public details include the SSH status.
Use the refresh icon next to the SSH information to run a manual check.

A successful SSH check verifies the trusted host key and authentication. It does
not execute a shutdown command or verify shutdown permissions.

WebSocket snapshots and status messages update the list automatically. Connection
loss displays a notice and triggers reconnection after three seconds. The backend
controls automatic TCP and SSH check intervals and authentication retry limits.
