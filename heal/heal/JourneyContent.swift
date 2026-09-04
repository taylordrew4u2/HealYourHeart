//
//  JourneyContent.swift
//  heal
//
//  The full Journey catalogue. Day numbers and phases follow the product
//  specification: Stabilize 1-7, Cut Off and Understand 8-14,
//  Untangle the Story 15-30, Rebuild Self-Trust 31-60, Move Forward 61-90.
//
//  A 60- or 90-day Journey is not a stretched 30-day Journey. Each length
//  keeps the same early days and adds real additional material.
//

import Foundation

enum JourneyPhase: String, CaseIterable, Identifiable {
    case stabilize = "Stabilize"
    case cutOffAndUnderstand = "Cut Off and Understand"
    case untangleTheStory = "Untangle the Story"
    case rebuildSelfTrust = "Rebuild Self-Trust"
    case moveForward = "Move Forward"

    var id: String { rawValue }

    var dayRange: ClosedRange<Int> {
        switch self {
        case .stabilize: 1...7
        case .cutOffAndUnderstand: 8...14
        case .untangleTheStory: 15...30
        case .rebuildSelfTrust: 31...60
        case .moveForward: 61...90
        }
    }

    static func phase(forDay day: Int) -> JourneyPhase {
        allCases.first { $0.dayRange.contains(day) } ?? .moveForward
    }
}

enum JourneyLibrary {
    static let availableLengths = [30, 60, 90]

    /// Every day of the longest Journey, in order. Day `n` always carries the
    /// same content, so changing Journey length adds or removes later days
    /// without rewriting the days already completed.
    static let allDays: [JourneyContentDay] = entries.enumerated().map { index, entry in
        let number = index + 1
        return JourneyContentDay(
            number: number,
            title: entry.title,
            phase: JourneyPhase.phase(forDay: number).rawValue,
            lesson: entry.lesson,
            action: entry.action,
            checkIn: entry.checkIn
        )
    }

    static func days(for length: Int) -> [JourneyContentDay] {
        Array(allDays.prefix(max(0, length)))
    }

    static func day(_ number: Int) -> JourneyContentDay? {
        allDays.first { $0.number == number }
    }

    private struct Entry {
        let title: String
        let lesson: String
        let action: String
        let checkIn: String
    }

    // MARK: - Phase 1: Stabilize (Days 1-7)

    private static let stabilize: [Entry] = [
        Entry(
            title: "Your Fragile Moments",
            lesson: "Your nervous system is trying to protect you by making everything feel urgent.",
            action: "Put one glass of water and one simple food choice within reach.",
            checkIn: "What part of today felt most fragile?"
        ),
        Entry(
            title: "Breathing Out",
            lesson: "Relief often starts by slowing the body before solving the story.",
            action: "Try four slow exhales before opening any old messages.",
            checkIn: "Did your body soften even a little?"
        ),
        Entry(
            title: "Taking Stock of the Storm",
            lesson: "A storm is easier to survive when you can name what is happening inside it.",
            action: "Name one feeling, one fact, and one thing you do not know yet.",
            checkIn: "Which part is fact, and which part is fear?"
        ),
        Entry(
            title: "Sleep Is Not a Reward",
            lesson: "Missing sleep makes grief louder and makes impulsive contact far more likely. Rest is not something you earn by feeling better first.",
            action: "Pick one hour tonight when your phone charges in another room.",
            checkIn: "What made lying down hardest?"
        ),
        Entry(
            title: "Something to Eat",
            lesson: "Appetite often disappears before the pain does. Low fuel gets misread by your mind as danger.",
            action: "Eat one thing today that takes no decision-making at all.",
            checkIn: "How did your body feel an hour after eating?"
        ),
        Entry(
            title: "Who Already Knows",
            lesson: "Support you already have works faster than support you have to build from nothing.",
            action: "Tell one person who already knows that you are having a hard week.",
            checkIn: "Who felt safest to tell, and why?"
        ),
        Entry(
            title: "The First Week Is Not the Verdict",
            lesson: "How you feel in the first week is not evidence about how you will feel in a month. Early pain is loud, not predictive.",
            action: "Name one thing you survived this week that you did not think you could.",
            checkIn: "What is one thing that is already slightly different from day one?"
        )
    ]

    // MARK: - Phase 2: Cut Off and Understand (Days 8-14)

    private static let cutOffAndUnderstand: [Entry] = [
        Entry(
            title: "Why the Silence",
            lesson: "Silence can feel like an answer, a punishment, or an invitation to chase. It may be none of those.",
            action: "Do not use silence as evidence of your worth today.",
            checkIn: "What meaning are you adding to the silence?"
        ),
        Entry(
            title: "One More Thread",
            lesson: "The urge to send one more message is usually the urge to end uncertainty, not the urge to communicate.",
            action: "Say the message out loud to your companion instead of sending it.",
            checkIn: "What were you actually asking them for?"
        ),
        Entry(
            title: "The Profile You Keep Opening",
            lesson: "Checking their profile gives your mind a hit of information and then leaves it hungrier. The relief lasts seconds; the comparison lasts hours.",
            action: "Move the app you use to check them off your home screen today.",
            checkIn: "What did you hope to find the last time you looked?"
        ),
        Entry(
            title: "Mixed Messages",
            lesson: "Warm words with cold behavior are not a puzzle to solve. Behavior over time is the message.",
            action: "Name what their actions have consistently done, apart from what was said.",
            checkIn: "Which do you keep believing: the words or the pattern?"
        ),
        Entry(
            title: "The Message You're Waiting For",
            lesson: "Waiting for a specific message can quietly organize an entire day around a person who is not there.",
            action: "Choose one hour today that belongs to something else entirely.",
            checkIn: "What would that message change tomorrow, honestly?"
        ),
        Entry(
            title: "Fantasy and Evidence",
            lesson: "Your mind will fill an information gap with a story. A story is not evidence, even when it is detailed.",
            action: "Separate one thing you know from one thing you are imagining.",
            checkIn: "Which one has been driving your decisions?"
        ),
        Entry(
            title: "The Wave of the Urge",
            lesson: "An urge rises, peaks, and falls. It asks for action, but it is not the same as a decision.",
            action: "Delay the next contact impulse by ten minutes and stay with your companion while it passes.",
            checkIn: "What outcome did the urge promise you?"
        )
    ]

    // MARK: - Phase 3: Untangle the Story (Days 15-30)

    private static let untangleTheStory: [Entry] = [
        Entry(
            title: "The Version You Miss",
            lesson: "Sometimes you miss a real person. Sometimes you miss the version of the relationship your mind edits together.",
            action: "Compare one warm memory with one fact you usually skip.",
            checkIn: "What changed when both were allowed in the room?"
        ),
        Entry(
            title: "The Highlight Reel",
            lesson: "Memory keeps the peaks and quietly drops the ordinary days. That is not lying to yourself; it is how memory works.",
            action: "Name one completely ordinary week of the relationship as it really was.",
            checkIn: "Was the ordinary week good?"
        ),
        Entry(
            title: "What You Edited Out",
            lesson: "The parts you skip when you tell the story are often the parts that were costing you the most.",
            action: "Tell your companion one thing you usually leave out when you describe them.",
            checkIn: "Why has that part been easier to leave out?"
        ),
        Entry(
            title: "Rejection Is Not a Ruling",
            lesson: "Not being chosen is information about fit and about them. It is not a verdict on your worth, even when it feels like one.",
            action: "Name one quality of yours that this ending did not touch.",
            checkIn: "Whose judgment have you been treating as final?"
        ),
        Entry(
            title: "The Conversation You Never Had",
            lesson: "An imagined conversation can run for months because you control both sides of it. It rarely ends the way you rehearse.",
            action: "Say the one sentence you most wanted to say, out loud, once.",
            checkIn: "What did saying it change, and what did it not?"
        ),
        Entry(
            title: "What Actually Happened",
            lesson: "Healing asks for the whole story: what was beautiful, what was painful, and what kept repeating.",
            action: "Tell your companion one pattern you do not want to normalize again.",
            checkIn: "What did you protect by telling the fuller truth?"
        ),
        Entry(
            title: "Whose Fault Was It",
            lesson: "Assigning all the blame in one direction is fast and rarely accurate. Responsibility is usually shared and unevenly.",
            action: "Name one thing that was theirs and one thing that was yours.",
            checkIn: "Which one was harder to say?"
        ),
        Entry(
            title: "The Shame Underneath",
            lesson: "Shame says the problem is you rather than something you did. It keeps you re-reading old messages looking for the moment you ruined it.",
            action: "Say the harshest sentence you tell yourself, then say what you would tell a friend who said it.",
            checkIn: "Would you accept that sentence as evidence about anyone else?"
        ),
        Entry(
            title: "The Pattern Before Them",
            lesson: "If this ache feels familiar, the relationship may have fit an older shape rather than created it.",
            action: "Name what this longing reminds you of from before them.",
            checkIn: "How old does this feeling actually feel?"
        ),
        Entry(
            title: "What You Wanted From Them",
            lesson: "Naming the specific thing you wanted — safety, attention, certainty, admiration — makes it possible to get it somewhere it can actually come from.",
            action: "Name the one thing you most wanted them to give you.",
            checkIn: "Where else could that need be met?"
        ),
        Entry(
            title: "What You Gave Up",
            lesson: "Attachment can quietly cost friendships, standards, sleep, and time. Counting the cost is not bitterness; it is accuracy.",
            action: "Name one thing you set aside during the relationship that you want back.",
            checkIn: "What would taking it back look like this week?"
        ),
        Entry(
            title: "The Apology That Isn't Coming",
            lesson: "Waiting for an apology hands someone the timing of your recovery. Some people never say it, including people who know they should.",
            action: "Name what you would do differently today if the apology had already arrived, then do one part of it.",
            checkIn: "What has waiting cost you so far?"
        ),
        Entry(
            title: "Anger Has Information",
            lesson: "Anger usually marks a boundary that was crossed. It is worth reading before it is worth releasing.",
            action: "Name the boundary your anger is pointing at.",
            checkIn: "Is the anger asking for revenge, or for protection?"
        ),
        Entry(
            title: "You Don't Need One More Answer",
            lesson: "Some answers would only create another question. Closure can start before certainty arrives.",
            action: "Write no letter. Send no proof. Choose one action that belongs only to your life.",
            checkIn: "What would you do tonight if no answer came?"
        ),
        Entry(
            title: "Grieving the Future You Planned",
            lesson: "Part of the pain is not the person. It is the version of your life you had already started living in.",
            action: "Name one plan you made with them that you are letting go of.",
            checkIn: "What part of that plan was actually about you?"
        ),
        Entry(
            title: "The Story You Can Live With",
            lesson: "You do not need a final, perfect account of what happened. You need one that is true and that lets you keep moving.",
            action: "Tell your companion the story of the relationship in five sentences.",
            checkIn: "What did the shorter version leave out, and did it need to be there?"
        )
    ]

    // MARK: - Phase 4: Rebuild Self-Trust (Days 31-60)

    private static let rebuildSelfTrust: [Entry] = [
        Entry(
            title: "Small Kept Promises",
            lesson: "Trust in yourself returns through kept promises, not one grand realization.",
            action: "Keep one small promise to yourself before noon.",
            checkIn: "What did you prove to yourself today?"
        ),
        Entry(
            title: "Your Own Morning",
            lesson: "The first hour of the day sets what your attention does with the other fifteen.",
            action: "Do one thing before checking your phone tomorrow.",
            checkIn: "Where did your attention go first today?"
        ),
        Entry(
            title: "The Room You Live In",
            lesson: "Your surroundings keep making an argument about how you are doing. It is easier to change the room than the mood.",
            action: "Reset one surface in the room where you spend the most time.",
            checkIn: "Did the space feel different afterwards?"
        ),
        Entry(
            title: "One Friend, One Message",
            lesson: "Isolation feels protective and works against you. Contact with one person breaks the loop faster than an hour of thinking.",
            action: "Send one message to a friend that is not about the breakup.",
            checkIn: "What did it feel like to talk about something else?"
        ),
        Entry(
            title: "What You Used to Love",
            lesson: "Interests do not disappear during a relationship; they get postponed. They usually come back faster than you expect.",
            action: "Spend fifteen minutes on something you loved before you met them.",
            checkIn: "Did any part of it still feel like yours?"
        ),
        Entry(
            title: "Moving the Body",
            lesson: "Grief sits in the body. Movement does not fix the story, but it changes the chemistry you are thinking inside of.",
            action: "Move for ten minutes in any way that does not require motivation.",
            checkIn: "What was different after moving?"
        ),
        Entry(
            title: "The Decisions You Made Right",
            lesson: "Self-trust is not rebuilt only by finding mistakes. You also made good calls, including hard ones.",
            action: "Name two decisions you made during the relationship that were sound.",
            checkIn: "Why has it been easier to remember the mistakes?"
        ),
        Entry(
            title: "Where You Ignored Yourself",
            lesson: "Most people can point to the moment they first overrode their own signal. That moment is information, not proof of stupidity.",
            action: "Name the first time you talked yourself out of something you noticed.",
            checkIn: "What did you know then that you know now?"
        ),
        Entry(
            title: "Learning Your Own Signals",
            lesson: "Your body often registers discomfort before your reasoning catches up. That signal is trainable.",
            action: "Notice one moment today when your body reacted before you had words.",
            checkIn: "What was it responding to?"
        ),
        Entry(
            title: "Saying No Out Loud",
            lesson: "A boundary you only hold internally gets tested constantly. One said out loud gets tested less.",
            action: "Say no to one small thing today without explaining yourself.",
            checkIn: "How did it feel not to justify it?"
        ),
        Entry(
            title: "The Work of an Ordinary Tuesday",
            lesson: "Recovery is mostly unremarkable days handled adequately, not breakthroughs.",
            action: "Do the two ordinary tasks you have been postponing.",
            checkIn: "What does an adequate day look like for you now?"
        ),
        Entry(
            title: "Money, Sleep, Food, Order",
            lesson: "The four dull systems hold up everything else. When they slide, emotional pain gets sharper for reasons that have nothing to do with them.",
            action: "Fix the one of the four that is furthest out of shape.",
            checkIn: "Which one has been quietly making things worse?"
        ),
        Entry(
            title: "Your Name Without Theirs",
            lesson: "For a while your identity was said in a pair. Getting used to the single version takes repetition, not insight.",
            action: "Describe yourself out loud in three sentences that do not mention them.",
            checkIn: "Which sentence came hardest?"
        ),
        Entry(
            title: "The People Who Stayed",
            lesson: "Attention goes to the person who left and skips the people who did not.",
            action: "Thank one person who has been steady with you.",
            checkIn: "Who have you been overlooking?"
        ),
        Entry(
            title: "Being Alone Without Being Lonely",
            lesson: "Solitude and loneliness feel similar and are not the same. One is chosen and refills you.",
            action: "Spend thirty minutes alone doing something you actually chose.",
            checkIn: "Was it emptiness, or was it quiet?"
        ),
        Entry(
            title: "What You Want to Be Known For",
            lesson: "Deciding what you want to be about redirects attention faster than deciding what to stop thinking about.",
            action: "Name the three qualities you want people to associate with you.",
            checkIn: "Which one did today support?"
        ),
        Entry(
            title: "Rebuilding Taste",
            lesson: "Preferences get blended in a relationship. Reclaiming small ones is a real way of coming back to yourself.",
            action: "Choose one thing today purely because you like it.",
            checkIn: "How quickly did you know what you wanted?"
        ),
        Entry(
            title: "The Second Wave",
            lesson: "Pain often returns after a good stretch. A return is not a relapse and it does not undo the weeks behind it.",
            action: "Name what you already know how to do when the wave comes.",
            checkIn: "What is different about how you handled it this time?"
        ),
        Entry(
            title: "When Someone Asks About Them",
            lesson: "Having a short, calm answer ready keeps other people's curiosity from setting off your whole day.",
            action: "Decide the one sentence you will say when someone asks.",
            checkIn: "Does that sentence protect you or perform for them?"
        ),
        Entry(
            title: "Places That Still Hurt",
            lesson: "Certain streets, rooms, and routines still carry them. Avoidance shrinks your life; deliberate exposure returns it.",
            action: "Go to one small place you have been avoiding, briefly and on purpose.",
            checkIn: "What was it actually like compared with what you expected?"
        ),
        Entry(
            title: "Music, Films, Streets",
            lesson: "Shared culture reattaches to you slowly. Reclaiming it works better than banning it forever.",
            action: "Play one song you have been avoiding, once, all the way through.",
            checkIn: "What did it bring back, and how long did it last?"
        ),
        Entry(
            title: "What Changed in You",
            lesson: "Some of what the relationship changed in you is worth keeping. Some of it is worth returning.",
            action: "Name one change you are keeping and one you are giving back.",
            checkIn: "Which change surprised you?"
        ),
        Entry(
            title: "The Standard You Set Now",
            lesson: "Standards set while you are steady hold better than standards set while you are hurt.",
            action: "Name one thing you will require in any future relationship.",
            checkIn: "Was that present with them?"
        ),
        Entry(
            title: "Flirting Without Fleeing",
            lesson: "Attention from someone new can be genuine interest or an exit from feeling. Both are common; only one helps right now.",
            action: "Notice one moment of attraction without acting on it.",
            checkIn: "Was it interest, or was it escape?"
        ),
        Entry(
            title: "Are You Ready, or Just Lonely",
            lesson: "Readiness for dating is not the absence of loneliness. It is being able to be alone without needing rescue.",
            action: "Answer honestly whether you want a person or want relief.",
            checkIn: "What would you be bringing to someone new right now?"
        ),
        Entry(
            title: "Comparing Yourself to Their Next",
            lesson: "Comparison uses their edited surface against your unedited interior. That contest is not winnable and not real.",
            action: "Stop one comparison today at the moment you notice it starting.",
            checkIn: "What were you trying to prove, and to whom?"
        ),
        Entry(
            title: "The Anniversary Problem",
            lesson: "Dates carry weight. Planned days hurt less than ambushed ones.",
            action: "Name the next date that will be hard and decide now what you will be doing.",
            checkIn: "Who could be with you that day?"
        ),
        Entry(
            title: "Trusting a Decision Again",
            lesson: "You do not need certainty to decide. You need to be able to live with having chosen.",
            action: "Make one decision today that you have been deferring.",
            checkIn: "How long had you been holding it?"
        ),
        Entry(
            title: "What Sixty Days Taught You",
            lesson: "Progress is easiest to see against where you started, not against where you wish you were.",
            action: "Name three things that are true now that were not true on day one.",
            checkIn: "What would day-one you find hard to believe?"
        ),
        Entry(
            title: "The Person You Are Becoming",
            lesson: "You are not returning to who you were before them. You are becoming someone who has been through this.",
            action: "Name one thing that version of you does differently.",
            checkIn: "What is the first step toward that person this week?"
        )
    ]

    // MARK: - Phase 5: Move Forward (Days 61-90)

    private static let moveForward: [Entry] = [
        Entry(
            title: "Some Things Stay Unresolved",
            lesson: "A number of things about this will never be settled. Acceptance is deciding to live well without the settlement.",
            action: "Name the one question you are choosing to stop asking.",
            checkIn: "What does putting it down make room for?"
        ),
        Entry(
            title: "Carrying It Without Holding It",
            lesson: "The feeling can exist without running the day. That is what carrying it looks like.",
            action: "Let one wave of feeling pass without changing your plans.",
            checkIn: "What did you do while it was happening?"
        ),
        Entry(
            title: "If They Come Back",
            lesson: "Deciding in advance protects you from deciding while flooded. Contact from them is a moment, not an emergency.",
            action: "Decide now what you would do if they messaged tomorrow.",
            checkIn: "What would you need to see before anything changed?"
        ),
        Entry(
            title: "If They Never Come Back",
            lesson: "A life built on their return is a life on hold. A life built without it can still be open.",
            action: "Name one thing you are building that does not depend on them at all.",
            checkIn: "Does that plan feel like a loss or like room?"
        ),
        Entry(
            title: "Answering an Old Message",
            lesson: "A reply sent quickly is usually written by the urge. A reply that can wait a day is usually written by you.",
            action: "Decide your waiting period before you ever reply to them again.",
            checkIn: "What outcome would you want from replying?"
        ),
        Entry(
            title: "Seeing Them Again",
            lesson: "Running into them will feel enormous and will end. Having a plan shrinks the aftermath.",
            action: "Decide the three things you would say and how you would leave.",
            checkIn: "Who would you call afterwards?"
        ),
        Entry(
            title: "Mutual Friends",
            lesson: "Shared people do not have to become messengers. You can ask not to be updated.",
            action: "Ask one person to stop passing on news about them.",
            checkIn: "What have those updates been doing to you?"
        ),
        Entry(
            title: "Photographs and Storage",
            lesson: "You do not have to delete everything or keep everything visible. Out of reach is enough for now.",
            action: "Move the photos somewhere you will not encounter them by accident.",
            checkIn: "What made that harder or easier than expected?"
        ),
        Entry(
            title: "What to Do With the Things",
            lesson: "Objects hold time. Deciding about them deliberately beats stumbling on them.",
            action: "Deal with one object you have been walking past.",
            checkIn: "What did you decide, and why that?"
        ),
        Entry(
            title: "Forgiveness Is Not Access",
            lesson: "You can stop carrying resentment without letting someone back in. They are separate decisions.",
            action: "Say which one you are actually considering.",
            checkIn: "Would forgiving change anything you would allow?"
        ),
        Entry(
            title: "Forgiving Yourself",
            lesson: "Most of what you are ashamed of was done by someone hurt and short of information. That deserves accuracy, not amnesty or attack.",
            action: "Say one thing you did that you regret, and what you now understand about it.",
            checkIn: "What would you say to someone else who did that?"
        ),
        Entry(
            title: "When the Ache Returns",
            lesson: "The ache gets less frequent long before it gets less sharp. Frequency is the honest measure.",
            action: "Note how many days it has been since the last hard hour.",
            checkIn: "Is it coming less often than it was?"
        ),
        Entry(
            title: "Measuring Progress Honestly",
            lesson: "Progress is not a straight line and not a mood. It is what you do on an average day.",
            action: "Name what an average day looks like now compared with month one.",
            checkIn: "What has quietly become normal again?"
        ),
        Entry(
            title: "Nights Are Still Nights",
            lesson: "Late hours amplify everything. A night plan matters more than a day plan.",
            action: "Decide what you do at 1am instead of opening their profile.",
            checkIn: "What does the night keep asking you to do?"
        ),
        Entry(
            title: "What Love Actually Looked Like",
            lesson: "Naming what was genuinely good keeps you honest, and keeps you from settling for less next time.",
            action: "Name one thing between you that was real and worth wanting again.",
            checkIn: "Can you want that again without wanting them?"
        ),
        Entry(
            title: "What You Will Not Accept Again",
            lesson: "Clear limits are easier to hold when they were decided calmly, in advance.",
            action: "Name three things you will not accept in a relationship again.",
            checkIn: "Which of the three was present with them?"
        ),
        Entry(
            title: "What You Will Offer",
            lesson: "Standards work in both directions. Knowing what you bring is as clarifying as knowing what you require.",
            action: "Name what you are genuinely good at in a relationship.",
            checkIn: "Where did you not get to use that?"
        ),
        Entry(
            title: "The Difference Between Chemistry and Safety",
            lesson: "Intensity and security feel very different. Intensity is easier to notice and much less useful over time.",
            action: "Name one relationship in your life that feels safe rather than intense.",
            checkIn: "Which one have you been treating as the real thing?"
        ),
        Entry(
            title: "Wanting Without Losing Yourself",
            lesson: "You can want someone and still keep your friends, sleep, standards, and plans. That combination is learnable.",
            action: "Name the one thing you will not give up next time, whoever it is.",
            checkIn: "When did you last give it up?"
        ),
        Entry(
            title: "Telling a New Person the Story",
            lesson: "How you tell it shapes how you carry it. A short, calm version means it is becoming history rather than news.",
            action: "Tell your companion the version you would tell someone new.",
            checkIn: "How long did that version take?"
        ),
        Entry(
            title: "Curiosity Instead of Chasing",
            lesson: "Interest that has to be pursued at cost is not interest being returned. Curiosity waits well.",
            action: "Notice one thing you are curious about that has nothing to do with them.",
            checkIn: "What did your attention do with the space?"
        ),
        Entry(
            title: "A Life With Room in It",
            lesson: "The point is not to fill every hour. It is to have a life that has space for someone without needing one.",
            action: "Leave one evening this week deliberately unplanned.",
            checkIn: "Was the empty evening restful or uncomfortable?"
        ),
        Entry(
            title: "Plans Beyond This Season",
            lesson: "Making a plan that lands months from now moves your attention forward more effectively than trying to think about them less.",
            action: "Put one thing in your calendar for three months from now.",
            checkIn: "How did looking that far ahead feel?"
        ),
        Entry(
            title: "Work, Purpose, Attention",
            lesson: "Work you care about does not cure grief, but it gives your attention somewhere honest to go.",
            action: "Give one hour of full attention to something you actually care about.",
            checkIn: "Where did your mind go when it wandered?"
        ),
        Entry(
            title: "Friendship as Its Own Love",
            lesson: "Romantic love is not the only love that counts. Friendship is not a placeholder for it.",
            action: "Make one plan with a friend that you will actually keep.",
            checkIn: "What have your friendships been carrying for you?"
        ),
        Entry(
            title: "The Version of You They Never Met",
            lesson: "You have changed in ways they will not see. That version is not a loss; it is the point.",
            action: "Name one thing about you now that they never knew.",
            checkIn: "Who did you become while they were gone?"
        ),
        Entry(
            title: "Gratitude Without Rewriting",
            lesson: "You can be glad something happened without pretending it ended well. Both can be true.",
            action: "Name one thing you are genuinely glad about, and one thing you are not.",
            checkIn: "Did holding both make it lighter or heavier?"
        ),
        Entry(
            title: "Letting the Chapter End",
            lesson: "Endings do not need ceremonies or agreement. They can simply be accepted.",
            action: "Say out loud that it is over, once, without arguing with it.",
            checkIn: "What did saying it change?"
        ),
        Entry(
            title: "Not Organized Around Them",
            lesson: "Moving forward does not require forgetting. It requires making your life larger than the ache.",
            action: "Plan one future-facing thing that has nothing to do with them.",
            checkIn: "Where did your attention belong today?"
        ),
        Entry(
            title: "You Can't Make Them Love You",
            lesson: "You could not have earned it, argued for it, or waited it out. That is the hardest fact here, and it is also the one that sets you free.",
            action: "Name what you are taking with you from these ninety days.",
            checkIn: "What do you want the next ninety days to be about?"
        )
    ]

    private static let entries: [Entry] =
        stabilize + cutOffAndUnderstand + untangleTheStory + rebuildSelfTrust + moveForward
}
