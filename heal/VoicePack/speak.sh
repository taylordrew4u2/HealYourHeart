#!/usr/bin/env bash
# Generate speech in Mara's cloned voice with F5-TTS.
# Setup (once):  pip install f5-tts
# Usage:         ./speak.sh "Text to say" output.wav
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
TEXT="${1:?text required}"; OUT="${2:-cloned.wav}"
f5-tts_infer-cli -m F5TTS_v1_Base \
  -r "$DIR/reference.wav" -s "$(cat "$DIR/reference.txt")" \
  -t "$TEXT" -o "$(dirname "$OUT")" -w "$(basename "$OUT")" --nfe_step 32
