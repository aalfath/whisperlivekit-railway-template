# WhisperLiveKit v0.2.28, official CPU image published by upstream (QuentinFuxa/WhisperLiveKit),
# pinned by tag and digest. Bump both together and add a CHANGELOG.md entry.
FROM ghcr.io/quentinfuxa/whisperlivekit:v0.2.28-cpu-diarization-sortformer@sha256:6b9ee6022eb05f61a13afb0841b88116baff2b55d83fe4d91a10a4ef3cfffa74

COPY patch.py start.sh /opt/railway/
RUN python /opt/railway/patch.py && chmod 0755 /opt/railway/start.sh

# Model downloads (Hugging Face) are cached on the Railway volume mounted at /data.
ENV PYTHONUNBUFFERED=1 \
    HF_HOME=/data/huggingface \
    XDG_CACHE_HOME=/data/cache \
    HF_HUB_DISABLE_TELEMETRY=1 \
    TOKENIZERS_PARALLELISM=false \
    MALLOC_ARENA_MAX=2

HEALTHCHECK --interval=30s --timeout=5s --start-period=300s --retries=3 \
  CMD python -c "import os,urllib.request; urllib.request.urlopen('http://127.0.0.1:%s/health' % os.environ.get('PORT','8000'))" || exit 1

ENTRYPOINT ["/opt/railway/start.sh"]
CMD []
