# Changelog

## v0.2.28 (2026-11-23)

First release of the Railway template.

- WhisperLiveKit v0.2.28, official CPU image `ghcr.io/quentinfuxa/whisperlivekit:v0.2.28-cpu-diarization-sortformer@sha256:6b9ee6022eb05f61a13afb0841b88116baff2b55d83fe4d91a10a4ef3cfffa74`.
- Faster-whisper backend with the LocalAgreement policy, `tiny` model by default, model cache on the `/data` volume.
- `WLK_API_TOKEN` is required; the browser UI reads it from `#token=` in the page address.
- Start script sizes threads, live sessions and the upload cap from the memory limit (fits Railway's 0.5 GB plan).
