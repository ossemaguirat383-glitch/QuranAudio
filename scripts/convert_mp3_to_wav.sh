#!/usr/bin/env bash
# Convert every .mp3 in the repo (outside ./wav and ./.git) to a parallel
# .wav under ./wav/, preserving the directory structure and filenames.
#
# Output WAV format: 44.1 kHz, 16-bit signed PCM, stereo.
# Existing output files are skipped so the script is resumable.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_ROOT="${REPO_ROOT}"
DST_ROOT="${REPO_ROOT}/wav"
JOBS="${JOBS:-$(nproc)}"

mkdir -p "${DST_ROOT}"

convert_one() {
    local src="$1"
    local rel="${src#${SRC_ROOT}/}"
    local dst="${DST_ROOT}/${rel%.mp3}.wav"
    if [[ -s "${dst}" ]]; then
        return 0
    fi
    mkdir -p "$(dirname "${dst}")"
    ffmpeg -hide_banner -loglevel error -nostdin -y \
        -i "${src}" -ar 44100 -ac 2 -acodec pcm_s16le -f wav \
        "${dst}.part" \
    && mv "${dst}.part" "${dst}"
}
export -f convert_one
export SRC_ROOT DST_ROOT

find "${SRC_ROOT}" \
    -path "${SRC_ROOT}/.git" -prune -o \
    -path "${DST_ROOT}" -prune -o \
    -type f -name '*.mp3' -print0 \
| xargs -0 -n1 -P "${JOBS}" bash -c 'convert_one "$0"'
