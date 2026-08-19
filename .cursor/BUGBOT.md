# BugBot review guide: shield-id-helper

A tiny Go native-messaging host. The browser extension cannot read the OS
hostname, internal IP, or OS user from its sandbox, so this companion returns
exactly those three fields over Chrome native messaging:
`{"hostname":"...", "internal_ip":"...", "os_user":"..."}`. It is deliberately
minimal, and its whole security value is that it stays that way. Review every
change against "does this let the host do more than report identity?"

## Invariant 1: never execute anything

The host reads identity from the OS API (`os.Hostname`, `user.Current`,
`net.InterfaceAddrs`) and returns it. It must NOT run commands or shell out.
Flag any introduction of `os/exec`, `exec.Command`, `syscall.Exec`, a shell
invocation, or any code that runs a program named or influenced by the incoming
message. A native-messaging host that executes is a remote-code-execution
primitive reachable from a compromised page through the extension.

## Invariant 2: the request is untrusted and action-agnostic

`identify()` already tolerates empty/garbage input and ignores the request's
contents. Keep it that way. Flag a PR that branches into different behavior
based on a field in the incoming message (an `action`, a path, a command),
because that turns a fixed reporter into a request-driven one.

## Invariant 3: bound the message framing

Native messaging frames a 4-byte little-endian length prefix before the JSON.
Reads must cap the declared length (Chrome's limit is 1 MB inbound) before
allocating, so a malformed prefix cannot drive an unbounded allocation. Flag a
read that trusts the length prefix without a ceiling.

## Invariant 4: report identity only, nothing more

The response shape is three fields. Do not widen it to environment variables,
full network configuration, running processes, file contents, or credentials.
Flag any change that adds a field carrying more than the minimal machine
identity the extension needs, or that reads a file/registry key it did not read
before.

## Invariant 5: only the Shield extension may connect

The native-messaging host manifest pins `allowed_origins` to the Shield
extension's ID. Flag any change that widens `allowed_origins`, adds a wildcard,
or adds another extension ID, and any packaging change that would install the
manifest with looser origins. A second allowed origin is a second caller for an
RCE-adjacent surface.

## General

- Errors are returned as `{"error":"..."}`; keep messages generic and avoid
  leaking full paths or environment detail.
- The build (`build.ps1`) and installer under `install/` place the manifest and
  binary; review those the same way — a writable install path or an unsigned
  binary undermines the whole trust story.
