# Heal Your Heart Acceptance Checklist

Use this checklist against the local prototype before replacing mock services with a backend provider.

- [ ] Onboarding stores the user name, remembered person, relationship details, contact status, contact goals, story, current hurt, hard behavior, and companion name.
- [ ] Closing and reopening the app preserves onboarding completion and profile answers.
- [ ] The Home screen does not show a no-contact streak unless the user selected a relevant contact goal or contact status.
- [ ] The Home screen contact count changes only after a confirmed slip event.
- [ ] Tapping I need you opens the hard-moment flow.
- [ ] I feel like reaching out supports action selection, urge strength, contact-event saving, and a delay timer.
- [ ] They contacted me accepts pasted text, separates next-action choices, and saves a non-resetting contact event.
- [ ] I slipped asks what happened and only saves a reset event after confirmation.
- [ ] I might not be safe prioritizes emergency and trusted-person support.
- [ ] Journey rows open a day detail screen with a short lesson, practical action, and simple check-in.
- [ ] Completing a Journey day changes Journey progress without depending on contact streaks.
- [ ] Chat and Talk messages are saved in the same history.
- [ ] Talk responses are spoken aloud and can be interrupted with Stop voice.
- [ ] Messages can be copied, deleted, marked important, remembered, and forgotten from the context menu.
- [ ] User messages can create memories linked to real source message IDs.
- [ ] What [Name] remembers lets the user search, edit, pin, delete, clear, and export memory data.
- [ ] Deleting a memory removes it from the local memory store.
- [ ] Settings discloses AI-generated responses and local prototype storage truthfully.
- [ ] The normal app UI does not call the companion an AI assistant, chatbot, therapist, or coach.
- [ ] Day and Night appearance modes use warm colors and avoid pure black or pure white as main interface colors.
- [ ] There is no Journal tab, journal prompt, or letters-you-will-never-send feature.

Manual Xcode setup still required before a production build:

- Set the app display name to Heal Your Heart in target build settings or Info.plist.
- Add microphone and speech-recognition usage descriptions before enabling real speech recognition.
- Configure backend endpoint, authentication, retention policy, and provider-key storage outside the iOS app.
- Add a real privacy policy and delete-account/delete-data process.
