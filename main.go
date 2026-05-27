// shield-id-helper — Chrome native-messaging companion for the Shield extension.
//
// The browser sandbox blocks the extension from reading the OS hostname, the
// LAN IP, or the logged-in OS user. This helper supplies those three fields
// over Chrome's native-messaging protocol so Shield events can be attributed
// to a real machine and account instead of just a public IP.
//
// Protocol: stdin/stdout, each message framed as a little-endian uint32 length
// followed by that many bytes of JSON. See:
//   https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging
//
// Request : {"action":"identify"}
// Response: {"hostname":"...", "internal_ip":"...", "os_user":"..."}
//
// The process is short-lived: Chrome spawns it on connectNative(), pipes one
// request, reads one response, then disconnects. We exit on EOF.

package main

import (
	"encoding/binary"
	"encoding/json"
	"io"
	"net"
	"os"
	"os/user"
)

type request struct {
	Action string `json:"action"`
}

type response struct {
	Hostname   string `json:"hostname,omitempty"`
	InternalIP string `json:"internal_ip,omitempty"`
	OSUser     string `json:"os_user,omitempty"`
	Error      string `json:"error,omitempty"`
}

// readMessage pulls one length-prefixed JSON message from r. Returns io.EOF
// when the peer closes (normal exit signal from Chrome).
func readMessage(r io.Reader) ([]byte, error) {
	var n uint32
	if err := binary.Read(r, binary.LittleEndian, &n); err != nil {
		return nil, err
	}
	// Chrome's spec caps incoming messages at 1MB. Reject larger to avoid
	// a malicious or buggy peer pinning memory.
	if n > 1024*1024 {
		return nil, io.ErrShortBuffer
	}
	buf := make([]byte, n)
	if _, err := io.ReadFull(r, buf); err != nil {
		return nil, err
	}
	return buf, nil
}

func writeMessage(w io.Writer, msg []byte) error {
	if err := binary.Write(w, binary.LittleEndian, uint32(len(msg))); err != nil {
		return err
	}
	_, err := w.Write(msg)
	return err
}

// primaryInternalIP returns the first non-loopback, non-link-local IPv4 the OS
// reports on an "up" interface. Good enough for endpoint attribution; we don't
// need every interface, just the one a SOC analyst could correlate with DHCP
// logs.
func primaryInternalIP() string {
	ifaces, err := net.Interfaces()
	if err != nil {
		return ""
	}
	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue
		}
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}
		for _, addr := range addrs {
			ipnet, ok := addr.(*net.IPNet)
			if !ok || ipnet.IP.IsLoopback() || ipnet.IP.IsLinkLocalUnicast() {
				continue
			}
			v4 := ipnet.IP.To4()
			if v4 == nil {
				continue
			}
			return v4.String()
		}
	}
	return ""
}

func identify() response {
	var r response
	if h, err := os.Hostname(); err == nil {
		r.Hostname = h
	}
	r.InternalIP = primaryInternalIP()
	if u, err := user.Current(); err == nil {
		// On AD-joined Windows this is `DOMAIN\username`. On macOS/Linux it's
		// the local account name. Either way it's the OS-level principal.
		r.OSUser = u.Username
	}
	return r
}

func main() {
	// Chrome sends exactly one request per spawned process. Reading in a loop
	// also handles the (rare) case where a peer pipelines multiple requests
	// before disconnect.
	for {
		raw, err := readMessage(os.Stdin)
		if err != nil {
			// io.EOF (or any read error) means the peer disconnected — normal exit.
			return
		}
		var req request
		_ = json.Unmarshal(raw, &req) // tolerate empty/garbage; identify() is action-agnostic

		resp := identify()
		out, err := json.Marshal(resp)
		if err != nil {
			out, _ = json.Marshal(response{Error: err.Error()})
		}
		if err := writeMessage(os.Stdout, out); err != nil {
			return
		}
	}
}
