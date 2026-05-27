# shield-id-helper

A small Chrome native-messaging companion for the [Shield](https://cinderlabs.ai)
browser extension. The browser sandbox blocks the extension from reading the
OS hostname, LAN IP, or logged-in OS user; this helper supplies those three
fields so Shield events can be attributed to a real machine and account
instead of just a public IP.

## What it sends

In response to each `{"action":"identify"}` request from the extension:

```json
{
  "hostname": "DESKTOP-ABC123",
  "internal_ip": "192.168.1.42",
  "os_user": "DOMAIN\\jdoe"
}
```

No network access, no persistent state, no telemetry. The helper exits when
the extension disconnects.

## Install

Download the zip for your OS from the [latest release](../../releases/latest),
extract it, then run the installer with your Shield extension ID.

You can find your extension ID at `chrome://extensions` (turn on Developer
mode if it's not visible).

### Windows

```powershell
# Elevated PowerShell
cd shield-id-helper-windows-amd64
.\install.ps1 -ExtensionId <your-shield-extension-id>
```

### macOS

```bash
sudo ./install.sh <your-shield-extension-id>
```

### Linux

```bash
sudo ./install.sh <your-shield-extension-id>
```

Restart Chrome after install. The extension picks up the helper on its next
heartbeat (within ~60 seconds).

## Uninstall

```powershell
# Windows (elevated)
.\uninstall.ps1
```

```bash
# macOS / Linux
sudo ./uninstall.sh
```

## Build from source

Requires Go 1.22+. From a checkout:

```powershell
.\build.ps1            # cross-compiles all 4 targets into dist/
```

Or for one target:

```bash
GOOS=linux GOARCH=amd64 go build -o shield-id-helper .
```

## Releases

Releases are cut by pushing a tag matching `v*`. GitHub Actions builds the
four bundles and attaches them to the release.

```bash
git tag v1.0.0
git push --tags
```
