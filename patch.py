"""Small, checked patches to the upstream package. The build fails if upstream code moved."""
import pathlib, sys
import whisperlivekit

pkg = pathlib.Path(whisperlivekit.__file__).parent

def patch(rel, old, new):
    p = pkg / rel
    s = p.read_text()
    if s.count(old) != 1:
        sys.exit(f"patch.py: expected exactly one match in {rel}: {old[:60]!r}")
    p.write_text(s.replace(old, new))
    print(f"patched {rel}")

# 1. Browser UI: when the server needs an API token, read it from the page address
#    (https://host/#token=... or ?token=...) and add it to the WebSocket URL.
patch(
    "web/live_transcription.js",
    'const defaultWebSocketUrl = `${protocol}://${host}${port ? ":" + port : ""}/asr`;',
    'const wlkPageToken = new URLSearchParams(window.location.hash.slice(1)).get("token") || '
    'new URLSearchParams(window.location.search).get("token") || "";\n'
    'const defaultWebSocketUrl = `${protocol}://${host}${port ? ":" + port : ""}/asr`'
    ' + (wlkPageToken ? "?token=" + encodeURIComponent(wlkPageToken) : "");',
)

# 2. REST upload cap from WLK_MAX_UPLOAD_MB (set by start.sh from the memory limit),
#    instead of a fixed 512 MB that a small container can't hold in memory.
patch(
    "basic_server.py",
    "_MAX_AUDIO_BYTES = 512 * 1024 * 1024",
    '_MAX_AUDIO_BYTES = int(os.environ.get("WLK_MAX_UPLOAD_MB", "512")) * 1024 * 1024',
)
patch(
    "basic_server.py",
    "max_upload_mb = 512",
    "max_upload_mb = _MAX_AUDIO_BYTES // (1024 * 1024)",
)
