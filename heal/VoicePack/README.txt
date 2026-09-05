Mara - cloned voice pack (F5-TTS zero-shot)

reference.wav / reference.txt  - the cleaned voice reference and its exact transcript.
                                 Use this pair with the local F5-TTS helper to speak as Mara.
sample_cloned_voice.m4a        - the bundled preview sample in Mara's voice.
speak.sh                       - generate new lines locally: ./speak.sh "your text" out.wav
generate-companion-line.sh     - generate app-ready files named heal/mara-line-<sha256>.wav.
                                 The app only plays these generated Mara voice assets;
                                 it does not fall back to Apple text-to-speech.
