#!/bin/sh
# Railway start script for WhisperLiveKit. Runs `wlk` as PID 1 (exec), so a crash or an
# out-of-memory kill exits non-zero and Railway's ON_FAILURE restart policy restarts it.
set -eu

if [ -z "${WLK_API_TOKEN:-}" ] || [ "${#WLK_API_TOKEN}" -lt 16 ]; then
  echo "start.sh: WLK_API_TOKEN must be set (16+ characters). Refusing to run an open transcription server." >&2
  exit 1
fi

# Memory limit (MB) and CPU count from the container's cgroup, not the host.
mem=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo max)
if [ "$mem" = "max" ]; then mem=$(awk '/MemTotal/ {print $2 * 1024}' /proc/meminfo); fi
mem_mb=$((mem / 1048576))
cpus=2
if read -r quota period < /sys/fs/cgroup/cpu.max 2>/dev/null && [ "$quota" != "max" ]; then
  cpus=$(( (quota + period - 1) / period ))
fi
[ "$cpus" -lt 1 ] && cpus=1
[ "$cpus" -gt 4 ] && cpus=4
if [ "$mem_mb" -lt 900 ]; then cpus=1; fi

threads=${WLK_THREADS:-$cpus}
export OMP_NUM_THREADS="$threads" MKL_NUM_THREADS="$threads" OPENBLAS_NUM_THREADS="$threads" NUMBA_NUM_THREADS="$threads"

# Below ~1 GB: no startup warm-up (it alone exceeds 512 MB), 2 live sessions, 25 MB uploads.
if [ "$mem_mb" -lt 900 ]; then
  sessions=2; upload_mb=25; set -- --warmup-file ""
elif [ "$mem_mb" -lt 1900 ]; then
  sessions=4; upload_mb=100; set --
else
  sessions=8; upload_mb=200; set --
fi
export WLK_MAX_UPLOAD_MB="${WLK_MAX_UPLOAD_MB:-$upload_mb}"

mkdir -p "$HF_HOME" "$XDG_CACHE_HOME"

echo "start.sh: memory ${mem_mb} MB, ${threads} thread(s), model ${WLK_MODEL:-tiny}, max sessions ${WLK_MAX_SESSIONS:-$sessions}, upload cap ${WLK_MAX_UPLOAD_MB} MB"

# shellcheck disable=SC2086
exec wlk \
  --host 0.0.0.0 \
  --port "${PORT:-8000}" \
  --model "${WLK_MODEL:-tiny}" \
  --language "${WLK_LANGUAGE:-auto}" \
  --backend-policy localagreement \
  --backend faster-whisper \
  --max-concurrent-sessions "${WLK_MAX_SESSIONS:-$sessions}" \
  --forwarded-allow-ips '*' \
  --log-level "${WLK_LOG_LEVEL:-INFO}" \
  "$@" ${WLK_EXTRA_ARGS:-}
