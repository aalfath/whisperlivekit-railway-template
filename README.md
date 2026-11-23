[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/whisperlivekit?utm_medium=integration&utm_source=button&utm_campaign=whisperlivekit)

# WhisperLiveKit on Railway

Railway template for [WhisperLiveKit](https://github.com/QuentinFuxa/WhisperLiveKit) **v0.2.28**: a self-hosted, real-time speech-to-text server with a browser UI, a live WebSocket API, an OpenAI-compatible `/v1/audio/transcriptions` endpoint and a Deepgram-compatible `/v1/listen` WebSocket. It runs on CPU with a small Whisper model, and every API call needs a generated token.

## What it deploys

One service, `WhisperLiveKit`, built from this repo:

- `Dockerfile`: upstream's official CPU image `ghcr.io/quentinfuxa/whisperlivekit:v0.2.28-cpu-diarization-sortformer`, pinned by digest, plus a small start script and two checked patches (`patch.py`).
- A volume at `/data` that caches the downloaded Whisper model, so restarts don't download it again.
- A public domain on `$PORT` with a health check at `/health`.

## Variables

| Variable | Default | What it does |
|---|---|---|
| `WLK_API_TOKEN` | `${{secret(48)}}` | Required token for the browser UI, WebSocket and REST APIs. Generated on deploy. |
| `WLK_MODEL` | `tiny` | Whisper model: `tiny`, `base`, `small`, `medium`, `large-v3`, `large-v3-turbo` (or `.en` variants). Bigger models need more RAM (see below). |
| `WLK_LANGUAGE` | `auto` | Spoken language code (`en`, `fr`, …) or `auto`. |
| `PORT` | `8000` | Port the server listens on. |

Optional, not in the template: `WLK_MAX_SESSIONS` (live sessions at once), `WLK_MAX_UPLOAD_MB` (REST upload cap), `WLK_THREADS` (CPU threads), `WLK_LOG_LEVEL`, and `WLK_EXTRA_ARGS` for any other `wlk` flag (for example `--target-language fr`).

## After deploy

Find `WLK_API_TOKEN` in the service's **Variables** tab. Then:

- **Browser UI:** open `https://YOUR-DOMAIN/#token=YOUR-TOKEN`, allow the microphone and press record.
- **OpenAI-compatible REST:**
  ```sh
  curl https://YOUR-DOMAIN/v1/audio/transcriptions -H "Authorization: Bearer YOUR-TOKEN" -F file=@audio.wav
  ```
  or `OpenAI(base_url="https://YOUR-DOMAIN/v1", api_key="YOUR-TOKEN")`.
- **Live WebSocket:** `wss://YOUR-DOMAIN/asr?token=YOUR-TOKEN` (upstream's native protocol) or `wss://YOUR-DOMAIN/v1/listen` with `Authorization: Token YOUR-TOKEN` (Deepgram-compatible).

## Memory and plans

The start script reads the service's memory limit and sizes itself:

- **Below 900 MB (Railway Free, 0.5 GB):** `tiny` model, 1 CPU thread, no start-up warm-up, at most 2 live sessions, 25 MB uploads. Tested at 0.5 GB with a live WebSocket session and a REST upload: about 380 MB in use.
- **900 MB–1.9 GB:** 4 sessions, 100 MB uploads. **2 GB and up:** 8 sessions, 200 MB uploads.

On CPU, `tiny` and `base` keep up with live speech; `small` needs about 1.5 GB and 2+ vCPU, `medium` and the `large` models need 3–6 GB and are slow without a GPU (Railway has none).

Upstream's default streaming policy (SimulStreaming) also loads a second copy of the model through PyTorch and doesn't fit in 0.5 GB, so this template uses the LocalAgreement policy with the faster-whisper backend. Speaker diarization, translation and the Voxtral/Qwen3 backends are off: they need several GB of RAM or a GPU. You can turn them on with `WLK_EXTRA_ARGS` on a bigger plan.

## Changes to upstream

- `start.sh` refuses to start without a `WLK_API_TOKEN` of 16+ characters, runs `wlk` as PID 1 so crashes exit non-zero (Railway restarts it), and caps CPU threads and sessions from the cgroup limits.
- `patch.py` lets the bundled browser UI take the token from the page address (`#token=…`), because upstream's UI has no token field, and makes the REST upload cap configurable. The build fails if upstream code moved.

## Updates

This template builds from this repo. When the pin in the `Dockerfile` is bumped on `main`, Railway shows an "update available" notice to everyone who deployed it, and you choose when to apply it. Read `CHANGELOG.md` first: breaking changes are listed at the top of each entry. The model cache on the volume is kept across updates.

## Licence

WhisperLiveKit is Apache-2.0 (© Quentin Fuxa). This wrapper is provided under the same licence.
