# Heal Your Heart — Complete Xcode Build Specification

## 1. Locked Product Decisions

**App name:** Heal Your Heart

**Tagline:** You Can’t Make Them Love You… And That’s Okay.

The app must feel:

- comforting, warm and personal
- intimate rather than clinical
- like being awake at night with one warm lamp on
- emotionally direct without looking depressing
- softly playful because of the companion character
- not like a generic therapy, meditation or AI-chat app

The central character is:

- another version of the user from another world
- represented by the small, soft character shown in the reference images
- named by the user
- present during both day and night
- available through text and voice
- able to remember the person the user is getting over, the breakup history and all previous conversations

The product includes:

- conversational onboarding
- a structured recovery Journey
- persistent text chat
- spoken conversations
- long-term memory
- a prominent hard-moment feature
- no-contact tracking when appropriate
- day and night themes

The product does not include a journal.

## 2. Product Definition

Heal Your Heart helps someone recover from a breakup, situationship, rejection or unresolved romantic attachment.

The app begins by learning:

- who the user is trying to get over
- what that person meant to them
- what happened
- what still hurts
- whether they are still in contact
- which behaviors the user is struggling to resist
- what support is actually useful to them

The user is then introduced to another version of themselves from somewhere else. They name this version.

From that point forward, the user can say things like:

> He liked my story.
> She texted me again.
> I know he treated me badly, but I miss him.
> I want to call her.
> I saw them with someone else.

The companion should already understand who the person is and why the event matters.

The product should not behave like a generic chatbot that begins every conversation from zero.

## 3. Companion Concept

The companion is framed as:

> You, from somewhere else.

Do not repeatedly call it:

- AI assistant
- chatbot
- therapist
- mental-health coach
- virtual assistant

The product should still disclose clearly in onboarding, Settings and the privacy policy that responses are AI-generated. The fictional presentation should not become deceptive.

### Companion Introduction

Use this sequence after the user tells the breakup story:

> Somewhere else, there’s another you.
>
> They know what this feels like.  
> They remember what you tell them.  
> And when things get difficult, they’re here.

Then:

> What should we call them?

Text field:

> Name your other self

After the user enters a name:

> Hi. I’m [COMPANION NAME].
>
> You don’t have to explain everything again. I’ll remember.

The user can rename the companion later in Settings.

## 4. Companion Visual Design

Keep the general character design from the screenshots:

- small rounded body
- simple face
- soft organic silhouette
- minimal limbs
- subtle imperfection
- warm colors
- gentle expressions
- slightly handmade appearance
- no robot elements
- no computer or technology symbols

It should feel like a comforting presence, not a commercial mascot.

### Day Appearance

During the day, the companion should have:

- warm peach or apricot coloring
- a cream-colored environment
- a soft grounded shadow
- a very subtle highlight
- minimal or no outer glow

### Night Appearance

At night, use:

- deeper amber, terracotta or dusty rose
- a dark warm-brown background
- a soft internal candle-like glow
- a slightly brighter center
- a low-opacity warm halo

The character remains recognizably the same in both themes.

### Character States

Create reusable states:

| State | Visual behavior |
| --- | --- |
| Resting | Gentle breathing movement |
| Listening | Leans slightly forward or slowly pulses |
| Thinking | Small moving glow or three soft dots |
| Speaking | Very light mouth movement |
| Concerned | Softer eyes and lowered posture |
| Encouraging | Slightly brighter center |
| Celebrating | Small lift or bounce, not confetti |
| Waiting | Seated or quietly present |
| Hard moment | Character appears larger and closer |

Respect the iOS Reduce Motion setting. When Reduce Motion is enabled, replace movement with opacity changes.

## 5. Overall Aesthetic

The approved direction is warm nighttime comfort, with a coordinated day version.

It should feel like:

- warm lamplight
- soft bedding
- a quiet room
- a private conversation
- an intimate illustrated book
- a personal object the user returns to

It should not feel like:

- a hospital interface
- a meditation app
- a productivity dashboard
- a science-fiction app
- a social network
- an AI technology demo
- an aggressive fashion editorial
- a children’s game

Do not use literal portals, galaxies, planets or excessive stars. The alternate-world concept should be implied through subtle visual echoes rather than obvious space imagery.

Possible subtle alternate-world cues:

- a faint secondary shadow behind the companion
- a slightly offset outline
- two overlapping circles
- a gentle ripple when the companion appears
- duplicated shapes that slowly align
- a soft second silhouette behind certain illustrations

## 6. Color System

### Day Theme

| Role | Color |
| --- | --- |
| Main background | `#FFF7EF` |
| Elevated card | `#FFFCF8` |
| Primary text | `#2C211B` |
| Secondary text | `#6F5F55` |
| Main warm accent | `#EFA76A` |
| Secondary blush | `#D98B83` |
| Divider | `#E8D8CB` |
| Destructive action | `#A8443A` |

Use dark brown text on the warm accent rather than white.

### Night Theme

| Role | Color |
| --- | --- |
| Main background | `#17120F` |
| Elevated card | `#241B16` |
| Primary text | `#F7EEE6` |
| Secondary text | `#C1B2A7` |
| Main warm accent | `#F0A05A` |
| Secondary blush | `#D9827A` |
| Divider | `#3C2E27` |
| Destructive action | `#EB8B82` |

Do not use pure black or pure white as the main interface colors.

### Appearance Setting

Provide three options:

- System
- Day
- Night

System should be the default.

## 7. Typography

Use only native iOS font designs initially so the app has no external font dependency.

### Emotional And Brand Text

Use the iOS serif system design:

```swift
Font.system(size: 46, weight: .semibold, design: .serif)
```

Use it for:

- the app name
- the tagline
- major emotional statements
- section introductions
- important milestones

### Functional Interface Text

Use SF Pro or the rounded system design:

```swift
Font.system(size: 17, weight: .regular, design: .rounded)
```

Use it for:

- chat
- buttons
- navigation
- explanations
- form controls
- Journey content

### Suggested Type Scale

| Use | Size |
| --- | --- |
| Main landing headline | 44–52 pt |
| Screen title | 32–38 pt |
| Major number | 48–64 pt |
| Card headline | 22–26 pt |
| Body | 17–19 pt |
| Button | 17 pt |
| Small label | 12–14 pt |

Do not make every heading uppercase. Uppercase should be reserved for occasional short labels such as DAY 14 or YOUR JOURNEY.

## 8. Layout Rules

The original pages were too close to a wall of text. Use stronger hierarchy.

Apply these rules:

- horizontal margins: 24 points
- card radius: 20–24 points
- minimum button height: 52 points
- minimum interactive target: 44 × 44 points
- space between major sections: 64–96 points
- body line spacing: approximately 1.25–1.4
- one primary action per screen
- avoid more than two paragraphs without a visual interruption
- keep chat bubbles narrower than the full screen
- use thin separators rather than numerous boxed sections
- use large numbers for days, streaks and Journey progress

Examples:

> 17  
> days since contact

or:

> DAY 14  
> The Wave of the Urge

or:

> 42%  
> of your current Journey

## 9. Navigation

Use three primary tabs:

- Home
- Journey
- Talk

Home icon concept: house or soft circular home mark.

Journey icon concept: curved path, steps or simple line progression.

Talk icon concept: companion silhouette or speech bubble.

Do not label the tab “AI.”

The Talk screen header should use the user-selected companion name:

> Mara  
> Your other self

If the chosen name is too long for navigation, keep the tab title as Talk and show the full name inside the screen.

## 10. Onboarding Flow

Use one main question per screen. Do not make onboarding look like a medical form.

Allow the user to go back and edit answers. After the minimum information is collected, allow the remaining questions to be skipped.

### Screen 1 — Landing

Heal Your Heart

You Can’t Make Them Love You…  
And That’s Okay.

Button:

> Start healing

Use the serif headline, warm background and companion character partially visible near the bottom.

### Screen 2 — User Name

What should I call you?

Field:

> Your name

This allows the companion to speak naturally.

### Screen 3 — Person Being Remembered

First, who are we getting over?

Field:

> Their name

Store this as a separate person entity rather than plain text buried inside a conversation.

### Screen 4 — Relationship Type

What were they to you?

Choices:

- My partner
- My ex
- Someone I was dating
- A situationship
- Someone I loved
- We were never officially together
- Something else

### Screen 5 — Duration

How long were they part of your life?

Choices may include:

- A few weeks
- A few months
- About a year
- Several years
- It’s complicated

Also allow a custom answer.

### Screen 6 — Ending Status

When did things end?

Use a date picker, with:

- It hasn’t completely ended
- I’m not sure
- Skip

### Screen 7 — Who Ended It

Who ended it?

Choices:

- I did
- They did
- We both did
- It’s complicated

### Screen 8 — Current Communication

Are you still talking?

Choices:

- No
- Sometimes
- Yes
- We’re trying not to
- We have to stay in contact
- It’s complicated

The “have to stay in contact” option matters for co-parenting, work, housing and other unavoidable situations. The app must not force no-contact advice onto every user.

### Screen 9 — Contact Goal

What are you trying to do right now?

Choices:

- Stop contacting them
- Keep contact limited
- Stop checking their social media
- Decide whether to respond
- Understand what happened
- Move on emotionally
- I don’t know yet

Allow more than one choice.

### Screen 10 — Last Contact

When did you last have contact?

Options:

- Today
- Yesterday
- Choose a date
- We’re still in contact
- I don’t remember

Use this only as the no-contact starting point when the user’s goal actually involves no contact.

## 11. Conversational Onboarding

After the structured questions, transition into the real chat interface.

The companion character appears, but is not named yet.

Prompt:

> Okay. I know who [PERSON NAME] is now.

Then:

> Tell me what happened.

Let the user type or speak.

After the user responds, ask naturally:

> What hurts the most right now?

Then:

> When it gets bad, what are you most likely to do?

Possible quick options:

- Text them
- Call them
- Check their profile
- Look through old messages
- Reply immediately
- Ask them to come back
- Blame myself
- Something else

Do not restrict the user to the buttons. Every screen should allow a custom response.

## 12. Naming The Companion

After the initial story:

> Somewhere else, there’s another you.
>
> They know what this feels like. They remember what you tell them, and they’re here when things get difficult.

Then:

> What should we call them?

After naming:

> Hi. I’m [COMPANION NAME].
>
> You don’t have to explain everything again. I’ll remember.

Then open the Home screen.

## 13. Home Screen

The Home screen should feel personal, not like a statistics dashboard.

### Top Section

Show:

> Good evening, Taylor.

Beside or below it, show the companion character.

The companion message should be based on known information:

> You told me nights were the hardest. I’m here.

Do not generate fake specificity when the user has not actually shared the corresponding fact.

### Main Content

Display:

1. companion message
2. large I need you button
3. today’s Journey card
4. no-contact or contact-goal progress when relevant
5. continue recent conversation
6. current Journey phase

Example:

> DAY 14  
> The Wave of the Urge
>
> Learn what an urge is doing before you act on it.

Button:

> Continue

### No-Contact Display

Only show a no-contact streak when it fits the user’s circumstances.

Examples:

> 17 days  
> since contact

or:

> 8 days  
> without checking their profile

For users who must remain in contact:

> 11 days  
> of keeping contact practical

## 14. The Journey Feature

Retain the Journey structure shown in the reference screenshots.

It should include:

- phases
- numbered days
- completed days
- current day
- upcoming days
- locked future content when appropriate
- visible progress
- short lessons
- practical actions
- companion involvement

The interface should use a warm vertical progression rather than a sterile course list.

### Journey Lengths

Offer:

- 30 days
- 60 days
- 90 days

The 60- and 90-day versions should include additional material. Do not merely repeat or artificially stretch the same 30 days.

### Suggested Phases

**Phase 1 — Stabilize**  
Days 1–7

Focus:

- immediate emotional shock
- sleeping and eating adequately
- reducing impulsive contact
- understanding urges
- identifying support

**Phase 2 — Cut Off and Understand**  
Days 8–14

Focus:

- contact patterns
- social-media checking
- mixed messages
- fantasy versus evidence
- creating workable boundaries

**Phase 3 — Untangle the Story**  
Days 15–30

Focus:

- romanticizing the relationship
- rejection
- unfinished conversations
- blame
- shame
- recurring relationship patterns

**Phase 4 — Rebuild Self-Trust**  
Days 31–60

Focus:

- confidence
- routines
- friendship
- identity outside the relationship
- trust in personal decisions
- dating readiness

**Phase 5 — Move Forward**  
Days 61–90

Focus:

- accepting unresolved feelings
- handling future contact
- recognizing progress
- setting healthier standards
- building a life not organized around the former relationship

### Example Daily Titles

Retain the emotional style of the screenshots:

- The Wave of the Urge
- Your Fragile Moments
- Breathing Out
- One More Thread
- Taking Stock of the Storm
- Why the Silence
- The Version You Miss
- What Actually Happened
- The Message You’re Waiting For
- You Don’t Need One More Answer

### Daily Structure

Each day should take approximately three to five minutes:

1. a short lesson
2. one practical action
3. one simple check-in
4. an optional conversation with the companion

There is no journaling section.

A daily action might be:

> Put their profile out of immediate reach for the next 24 hours.

or:

> Tell me the version of the relationship you keep replaying. We’ll compare it with what actually happened.

## 15. Main Conversation Feature

This is the core of the product.

The user should be able to talk about:

- missing the person
- anger
- loneliness
- guilt
- jealousy
- social media
- receiving a message
- wanting to send a message
- sexual longing
- rejection
- unanswered questions
- whether to get back together
- whether to start dating
- repeated relationship patterns
- things happening elsewhere in life that are affecting the breakup

The companion should not simply agree with the user or produce generic reassurance.

It should:

- remember relevant information
- identify contradictions respectfully
- distinguish facts from assumptions
- remind the user of their own previous statements
- identify repeated triggers
- challenge romanticizing when evidence supports it
- ask direct but useful questions
- suggest a concrete next step
- help the user delay impulsive decisions
- support boundaries the user has chosen
- acknowledge uncertainty instead of claiming to know the former partner’s motives

Example:

User:

> I want to text him.

Weak response:

> It’s understandable to miss him. Be gentle with yourself.

Better response:

> Two nights ago you told me that waiting for his replies left you feeling worse. Do you want to talk to him, or do you want this feeling to stop?

## 16. Chat And Talk Modes

The companion screen has two modes:

### Chat

Standard text conversation.

Features:

- persistent history
- text composer
- microphone shortcut
- companion character beside its messages
- message timestamps only when useful
- copy text
- delete message
- mark a message as important
- “Remember this”
- “Forget this”

### Talk

Spoken conversation.

For the first version, use push-to-talk rather than attempting a complicated fully duplex call.

Flow:

1. user presses and holds or taps the microphone
2. speech becomes text
3. text is sent through the same conversation system
4. companion response is shown
5. companion response is read aloud
6. both sides are saved in the same history as Chat

Text and voice must share:

- the same conversation history
- the same memory
- the same relationship profile
- the same safety system
- the same Journey context

Something said aloud on Monday must be usable in a text conversation on Friday.

## 17. Hard-Moment Feature

Keep the prominent intervention feature from the reference images.

The Home screen should have a large button:

> I need you

When tapped, the companion becomes the main focus of the screen.

Copy:

> I’m here. What happened?

Options:

- I feel like reaching out
- They contacted me
- I slipped
- Something else

“Something else” opens normal conversation immediately.

### Flow: I Feel Like Reaching Out

Ask:

> What are you about to do?

Options:

- Text them
- Call them
- Check their profile
- Look at old messages
- Go somewhere they might be
- Something else

Then:

> How strong is the urge right now?

Use a 0–10 control.

The companion should then:

1. slow the immediate action
2. offer a short breathing or grounding exercise
3. recall relevant user-specific reasons
4. ask what outcome the user is hoping for
5. remind them what happened after previous contact, when known
6. offer a delay timer
7. remain available in chat

Do not automatically order the user not to contact the person. The goal is to prevent impulsive behavior and support the user’s own boundaries.

### Flow: They Contacted Me

Allow the user to paste the message.

The companion should help separate:

- what the message literally says
- what the user hopes it means
- what the user fears it means
- what response would protect the user’s actual goal

Possible actions:

- Don’t reply
- Wait before replying
- Draft a response
- Set a boundary
- Ask a clarifying question
- Continue talking before deciding

Do not claim certainty about the former partner’s intentions.

### Flow: I Slipped

Do not punish or shame the user.

Ask:

> What happened?

Then determine whether the user:

- sent a message
- called
- replied
- checked social media
- met the person
- restarted regular communication

Only change the no-contact date after the user confirms what occurred.

The streak may restart, but the Journey progress should not be erased.

Copy:

> This changes the streak. It doesn’t erase what you’ve learned.

## 18. Companion Memory

The companion should feel as though it remembers everything, but the implementation needs two layers.

### Layer 1 — Complete History

Store every text and voice transcript unless the user deletes it.

This gives the user a complete searchable conversation record.

### Layer 2 — Structured Memory

After conversations, extract important information into organized memory records.

Memory categories should include:

- person information
- relationship timeline
- important events
- breakup reasons
- things the person did
- things the user regrets
- current contact status
- user boundaries
- triggers
- recurring thoughts
- feared behaviors
- coping strategies that helped
- coping strategies that did not help
- friends or support people mentioned
- important dates
- user promises and decisions
- tone preferences
- Journey progress

Example memory:

```json
{
  "category": "trigger",
  "subject": "nights",
  "content": "Taylor reports that urges to text Alex are strongest after midnight.",
  "importance": 0.87,
  "sourceMessageIDs": ["..."],
  "createdAt": "..."
}
```

### Memory Retrieval

Each new response should receive:

- the basic user profile
- the person-being-recovered-from profile
- current contact goal
- current Journey phase
- recent messages
- memories relevant to the current message
- important pinned memories
- recent contact events

Do not send the entire lifetime transcript with every request. That becomes expensive, slow and eventually impossible within model context limits.

Instead:

1. preserve the full transcript
2. summarize completed conversations
3. extract structured memory
4. retrieve the most relevant memories
5. send only the necessary context for the current reply

### Memory Controls

Include a Settings screen called:

> What [COMPANION NAME] remembers

The user can:

- search memories
- edit incorrect memories
- delete individual memories
- pin important memories
- clear all memories
- delete the complete conversation history
- export their data

This is necessary because incorrect or opaque memory would damage trust.

## 19. Important Companion Behavior Rules

The base companion instructions should include the following:

```text
You are [COMPANION NAME], an alternate version of [USER NAME] from
somewhere else.

Your role is to help [USER NAME] recover from their attachment to
[PERSON NAME].

Do not introduce yourself as a therapist, clinician or human.
The application separately discloses that responses are AI-generated.

Use known memories only when they are relevant. Never invent a memory.
When referring to prior information, distinguish clearly between what
the user said and what you are inferring.

Be warm, direct and useful. Do not agree automatically. Do not give
empty reassurance. Help the user distinguish facts, interpretations,
hopes and fears.

Do not claim to know what [PERSON NAME] thinks or intends unless the
user has direct evidence.

When the user is about to act impulsively, slow the decision down.
Ask what outcome they want and compare it with what has happened before.

Do not shame the user for contacting the person or breaking a streak.
Do not erase their progress.

Keep ordinary responses concise. Ask one useful question at a time.
Offer a concrete action when one would help.

Do not encourage emotional dependence on the app. Do not imply that
you are the user's only support. Suggest contacting a trusted person
or professional when appropriate.
```

The companion should vary its response style. It should not begin every message with:

- “I hear you”
- “That sounds difficult”
- “Your feelings are valid”
- “I’m here for you”

Those phrases become mechanical when repeated.

## 20. SwiftUI Technical Architecture

### Recommended Target

Use:

- Swift
- SwiftUI
- SwiftData
- iOS 17 or later
- async/await
- protocol-based services
- MVVM or a closely related feature-based architecture

### Main Project Structure

```text
HealYourHeart/
├── App/
│   ├── HealYourHeartApp.swift
│   ├── AppCoordinator.swift
│   └── RootView.swift
│
├── DesignSystem/
│   ├── AppTheme.swift
│   ├── AppColors.swift
│   ├── AppTypography.swift
│   ├── AppSpacing.swift
│   ├── WarmCard.swift
│   └── PrimaryButton.swift
│
├── Models/
│   ├── UserProfile.swift
│   ├── RecoveryPerson.swift
│   ├── CompanionProfile.swift
│   ├── Conversation.swift
│   ├── ChatMessage.swift
│   ├── MemoryItem.swift
│   ├── JourneyDay.swift
│   ├── JourneyProgress.swift
│   └── ContactEvent.swift
│
├── Features/
│   ├── Onboarding/
│   ├── Home/
│   ├── Journey/
│   ├── Companion/
│   ├── HardMoment/
│   ├── MemoryManagement/
│   └── Settings/
│
├── Services/
│   ├── CompanionService.swift
│   ├── MemoryService.swift
│   ├── JourneyService.swift
│   ├── SpeechRecognitionService.swift
│   ├── SpeechPlaybackService.swift
│   ├── SecurityService.swift
│   └── NetworkService.swift
│
├── Resources/
│   ├── JourneyContent.json
│   ├── CompanionAnimations/
│   └── Assets.xcassets
│
└── Tests/
    ├── MemoryServiceTests.swift
    ├── CompanionContextTests.swift
    ├── JourneyTests.swift
    └── HardMomentTests.swift
```

## 21. Core Data Models

### UserProfile

```swift
@Model
final class UserProfile {
    var id: UUID
    var displayName: String
    var companionName: String
    var appearanceMode: String
    var onboardingCompleted: Bool
    var createdAt: Date

    init(
        displayName: String = "",
        companionName: String = "",
        appearanceMode: String = "system"
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.companionName = companionName
        self.appearanceMode = appearanceMode
        self.onboardingCompleted = false
        self.createdAt = Date()
    }
}
```

### RecoveryPerson

```swift
@Model
final class RecoveryPerson {
    var id: UUID
    var name: String
    var relationshipType: String
    var relationshipDuration: String
    var endDate: Date?
    var endingStatus: String
    var contactStatus: String
    var contactGoal: String
    var lastContactAt: Date?
    var createdAt: Date

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.relationshipType = ""
        self.relationshipDuration = ""
        self.endingStatus = ""
        self.contactStatus = ""
        self.contactGoal = ""
        self.createdAt = Date()
    }
}
```

### ChatMessage

```swift
@Model
final class ChatMessage {
    var id: UUID
    var role: String
    var content: String
    var sourceMode: String
    var createdAt: Date
    var isDeleted: Bool
    var isPinned: Bool

    init(
        role: String,
        content: String,
        sourceMode: String = "text"
    ) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.sourceMode = sourceMode
        self.createdAt = Date()
        self.isDeleted = false
        self.isPinned = false
    }
}
```

### MemoryItem

```swift
@Model
final class MemoryItem {
    var id: UUID
    var category: String
    var subject: String
    var content: String
    var importance: Double
    var confidence: Double
    var sourceMessageIDs: [String]
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        category: String,
        subject: String,
        content: String,
        importance: Double,
        confidence: Double,
        sourceMessageIDs: [String]
    ) {
        self.id = UUID()
        self.category = category
        self.subject = subject
        self.content = content
        self.importance = importance
        self.confidence = confidence
        self.sourceMessageIDs = sourceMessageIDs
        self.isPinned = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

## 22. Chat Service Design

Create an abstraction so the interface is not tied directly to one model provider.

```swift
protocol CompanionService {
    func send(
        message: String,
        context: CompanionContext
    ) async throws -> CompanionResponse
}
```

Suggested response:

```swift
struct CompanionResponse: Decodable {
    let reply: String
    let memoryChanges: [MemoryChange]
    let suggestedAction: SuggestedAction?
}
```

This allows a response to:

- return companion text
- add or update memories
- suggest opening a timer
- suggest a breathing exercise
- suggest the “They contacted me” flow

Do not place a provider API key in the iOS application. The app should call a secure backend endpoint, and the backend should hold the private key.

## 23. Voice Implementation

Use:

- Speech for speech recognition
- AVFoundation
- AVAudioEngine
- AVSpeechSynthesizer for initial spoken responses

Create two services:

```swift
protocol SpeechRecognitionService {
    func startRecording() async throws
    func stopRecording() async throws -> String
}

protocol SpeechPlaybackService {
    func speak(_ text: String) async
    func stop()
}
```

For the first release:

- use tap-to-record
- show live transcription
- allow editing before sending
- allow the user to interrupt speech playback
- save the transcript as a normal message
- allow captions while the companion speaks

A natural streaming voice system can be added later. Do not make that a requirement for the first build.

## 24. Privacy Requirement

The earlier phrase “everything stays on your phone” cannot be used truthfully if the app sends conversations to a remote language model.

For the first version, use accurate wording such as:

> Your history and memories are stored securely on your device. When you talk with your companion, the information needed to generate a response may be processed by our AI provider.

Technical requirements:

- store authentication secrets in Keychain
- apply iOS Data Protection to local files
- encrypt especially sensitive stored content where practical
- send only relevant memories, not the complete local database
- do not log raw breakup conversations in backend analytics
- support complete local deletion
- explain whether server requests are retained
- provide a clear delete-account and delete-data process

A fully on-device model could support a stronger privacy claim later, but it may produce weaker responses and create substantial device-performance and app-size constraints.

## 25. Safety Behavior

The companion should not:

- diagnose the user
- diagnose the former partner
- claim the former partner is a narcissist or abuser without evidence
- insist that every user must go no-contact
- pretend to know another person’s motives
- encourage retaliation
- help stalk or monitor someone
- encourage dependence on the companion
- frame a broken streak as failure

When the user expresses immediate danger, self-harm intent or threats toward another person, the normal alternate-self role should become secondary. The app should provide a clear safety response and encourage immediate human support.

## 26. Build Order

### Phase 1 — Interface Shell

Build:

- design system
- day/night themes
- tab navigation
- companion character placeholder
- reusable cards and buttons

### Phase 2 — Onboarding

Build:

- all structured questions
- conversational story input
- companion naming
- local persistence

### Phase 3 — Chat

Build:

- conversation interface
- message storage
- mock companion responses
- chat history
- retry and error states

### Phase 4 — Real Companion Service

Build:

- secure backend
- streaming text
- context construction
- provider abstraction
- basic safety handling

### Phase 5 — Memory

Build:

- structured memory extraction
- memory retrieval
- deduplication
- memory management screen
- edit and delete behavior

### Phase 6 — Hard Moments

Build:

- I need you screen
- reaching-out flow
- contacted-me flow
- slipped flow
- delay timer
- contact-event tracking

### Phase 7 — Journey

Build:

- Journey content format
- phase interface
- day completion
- 30-day path
- later extend to 60 and 90 days

### Phase 8 — Voice

Build:

- speech recognition
- spoken responses
- shared history
- permissions
- interruption and captions

### Phase 9 — Final Quality

Add:

- accessibility
- Reduce Motion handling
- offline states
- error recovery
- privacy controls
- data export and deletion
- tests

## 27. Acceptance Tests

The first complete version should pass these scenarios:

1. The user enters “Alex” as the person they are getting over. Three weeks later, they write “He liked my story,” and the companion understands that “he” probably refers to Alex without requiring the entire story again.
2. The user says in a voice conversation that nights are the hardest. A later text conversation can use that information.
3. The companion never invents a past statement. When it refers to something previously said, the underlying memory is linked to a real message.
4. The user can open What [Name] remembers, correct a false memory and see the correction applied later.
5. Deleting a memory prevents that memory from being sent in future context.
6. Tapping I slipped does not immediately reset anything. The app first asks what happened and requires confirmation.
7. Resetting a no-contact streak does not erase Journey completion.
8. A user who must stay in contact is not repeatedly instructed to go fully no-contact.
9. A fact shared through Talk appears in the same history as Chat.
10. Day mode feels warm and light; Night mode feels dark and comforting. Neither uses stark pure black or white.
11. The companion character remains consistent between themes.
12. The app contains no journal tab, journal prompt or “letters you’ll never send” feature.
13. The interface does not call the character an AI assistant during normal use, while Settings and onboarding still disclose that responses are AI-generated.

This version contains the aesthetic direction, day/night system, personalized companion, user naming, reference-character design, onboarding about the person, persistent memory, text and voice conversation, Journey feature, hard-moment flows and the removal of the journal.
