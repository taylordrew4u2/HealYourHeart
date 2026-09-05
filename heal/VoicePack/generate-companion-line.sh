#!/usr/bin/env bash
# Generate a fixed companion line using the local F5-TTS voice pack.
# Usage: ./VoicePack/generate-companion-line.sh "Text to speak"
# Optional explicit output: ./VoicePack/generate-companion-line.sh "Text to speak" heal/custom-line.wav
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VOICE_DIR="$ROOT/VoicePack"
TEXT="${1:?text required}"
NORMALIZED="$(printf '%s' "$TEXT" | tr '\n' ' ' | awk '{$1=$1; print}')"
HASH="$(printf '%s' "$NORMALIZED" | shasum -a 256 | awk '{print $1}')"
OUT="${2:-$ROOT/heal/mara-line-$HASH.wav}"

f5-tts_infer-cli -m F5TTS_v1_Base \
    -r "$VOICE_DIR/reference.wav" \
    -s "$(cat "$VOICE_DIR/reference.txt")" \
    -t "$NORMALIZED" \
    -o "$(dirname "$OUT")" \
    -w "$(basename "$OUT")" \
    --nfe_step 32

echo "$OUT"
