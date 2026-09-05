# Heal Your Heart Acceptance Checklist

Use this checklist against a build on a real device. Everything runs on-device, so there is nothing to point at a server first.

- [ ] Onboarding stores the user name, remembered person, relationship details, contact status, contact goals, story, current hurt, hard behavior, and companion name.
- [ ] Onboarding lets the user optionally add a trusted support name and phone without requiring one.
- [ ] Closing and reopening the app preserves onboarding completion and profile answers.
- [ ] The Home screen does not show a no-contact streak unless the user selected a relevant contact goal or contact status.
- [ ] The Home screen contact count changes only after a confirmed slip event.
- [ ] Tapping I need you opens the hard-moment flow.
- [ ] The hard-moment flow lets the user start a voice call without first choosing a category.
- [ ] I feel like reaching out supports action selection, urge strength, contact-event saving, and a delay timer.
- [ ] They contacted me accepts pasted text, separates next-action choices, and saves a non-resetting contact event.
- [ ] I slipped asks what happened and only saves a reset event after confirmation.
- [ ] I might not be safe prioritizes emergency and trusted-person support.
- [ ] Journey rows open a day detail screen with a short lesson, practical action, and simple check-in.
- [ ] Journey day notes save locally, reappear when the day is reopened, and appear in exported local data.
- [ ] Journey rows indicate when a day has a saved note.
- [ ] Completing a Journey day changes Journey progress without depending on contact streaks.
- [ ] A new Journey starts at 0% with day 1 current and no days pre-completed.
- [ ] The Journey lists every day of the selected length, grouped by phase, with later days locked until they are reached.
- [ ] Switching between 30, 60, and 90 days keeps completed days and adds real additional material rather than repeating the first 30.
- [ ] The Home day card, phase name, and percentage match the Journey tab.
- [ ] Continue on the Home day card opens the current day and can complete it.
- [ ] Home lets the user save a soft feeling check-in and start a call from that feeling.
- [ ] Feeling check-ins are included in exported local data and cleared by Delete all local app data.
- [ ] Chat and Talk messages are saved in the same history.
- [ ] Talk tab offers one-tap soft starts for users who cannot compose a full message.
- [ ] Companion messages show suggested replies so the user can keep chatting with taps instead of typing.
- [ ] Talk responses are spoken aloud and can be interrupted with Stop voice.
- [ ] Home opens an in-app call where the companion speaks first.
- [ ] Every Journey day has a Talk to me button that opens a voice transcription flow for that entry.
- [ ] Call transcripts are saved into the same conversation and memory history as typed chat.
- [ ] Call responses are spoken aloud, shown on screen, repeatable, and interruptible.
- [ ] In-app call offers one-tap prompts for I feel alone, Stay with me, and I want to reach out.
- [ ] One-tap call prompts save into the same conversation and receive spoken companion replies.
- [ ] Messages can be copied, deleted, marked important, remembered, and forgotten from the context menu.
- [ ] User messages can create memories linked to real source message IDs.
- [ ] What [Name] remembers lets the user search, edit, pin, delete, clear, and export memory data.
- [ ] Deleting a memory removes it from the local memory store.
- [ ] Delete all local app data immediately returns the app to setup without requiring relaunch.
- [ ] Settings discloses generated responses and on-device storage truthfully without labeling the companion as a bot.
- [ ] Settings states correctly whether Apple's on-device model is answering on this device.
- [ ] Replies still arrive on a device without Apple's on-device model.
- [ ] A safety message gets the safety response without going through the model.
- [ ] The in-app call provides emergency and crisis support actions without requiring exact trigger words.
- [ ] Safety flows still work compassionately when the user has no personal support contact saved.
- [ ] The normal app UI does not call the companion an AI assistant, chatbot, therapist, or coach.
- [ ] Day and Night appearance modes use warm colors and avoid pure black or pure white as main interface colors.
- [ ] There is no Journal tab, journal prompt, or letters-you-will-never-send feature.

Configured in the Xcode project:

- App display name is Heal Your Heart (`INFOPLIST_KEY_CFBundleDisplayName`).
- Microphone and speech-recognition usage descriptions are set, so recording can be enabled.
- Bundle identifier is `com.healyourheart.app`.
- The target ships iOS only, matching its use of UIKit, AVAudioSession, and iOS-only SwiftUI modifiers.
- App icon and accent color are filled in.

Still required before submitting to the App Store:

- Replace the placeholder app icon with final artwork if you want something other than the generated one.
- Add a privacy policy URL in App Store Connect. The app itself has no account and no server, so data deletion is Delete all local app data in Settings.
- Test on a device with Apple Intelligence available and on one without, since the companion answers differently in each case.

The app uses Apple frameworks only: SwiftUI, SwiftData, AVFoundation, Speech, FoundationModels, and Keychain. There is no backend, no account, no third-party SDK, and no paid service.
