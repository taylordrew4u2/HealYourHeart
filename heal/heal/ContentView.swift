//
//  ContentView.swift
//  heal
//
//  Created by Taylor Drew on 9/4/26.
//

import SwiftUI
import UIKit
import AVFoundation

struct ContentView: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("storedProfile") private var storedProfile = ""
    @AppStorage("storedOnboardingCompleted") private var storedOnboardingCompleted = false
    @State private var profile = AppProfile()
    @State private var onboardingCompleted = false

    private var mode: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }

    var body: some View {
        ThemedRoot(appearanceMode: mode) {
            if onboardingCompleted {
                MainAppView(profile: $profile, appearanceMode: $appearanceMode)
            } else {
                OnboardingView(profile: $profile) {
                    onboardingCompleted = true
                }
            }
        }
        .onAppear(perform: loadStoredState)
        .onChange(of: profile) { _, newValue in
            storedProfile = LocalPersistence.encode(newValue)
        }
        .onChange(of: onboardingCompleted) { _, newValue in
            storedOnboardingCompleted = newValue
        }
    }

    private func loadStoredState() {
        profile = LocalPersistence.decode(AppProfile.self, from: storedProfile) ?? AppProfile()
        onboardingCompleted = storedOnboardingCompleted
    }
}

// MARK: - App State

struct AppProfile: Codable, Equatable {
    var userName = ""
    var personName = ""
    var relationshipType = ""
    var duration = ""
    var endingStatus = ""
    var endedBy = ""
    var contactStatus = ""
    var contactGoals: Set<String> = []
    var lastContact = ""
    var story = ""
    var currentHurt = ""
    var hardBehavior = ""
    var companionName = ""

    var displayName: String {
        userName.isEmpty ? "there" : userName
    }

    var rememberedPerson: String {
        personName.isEmpty ? "them" : personName
    }

    var companionDisplayName: String {
        companionName.isEmpty ? "Mara" : companionName
    }

    var shouldShowContactProgress: Bool {
        contactGoals.contains("Stop contacting them") ||
        contactGoals.contains("Keep contact limited") ||
        contactGoals.contains("Stop checking their social media") ||
        contactStatus == "We have to stay in contact"
    }

    var contactProgressLabel: String {
        if contactStatus == "We have to stay in contact" {
            return "of keeping contact practical"
        }
        if contactGoals.contains("Stop checking their social media") {
            return "without checking their profile"
        }
        return "since contact"
    }
}

enum LocalPersistence {
    static func encode<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    static func decode<T: Decodable>(_ type: T.Type, from string: String) -> T? {
        guard let data = string.data(using: .utf8), !data.isEmpty else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case day
    case night

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .day: "Day"
        case .night: "Night"
        }
    }
}

enum CompanionState {
    case resting
    case listening
    case thinking
    case speaking
    case concerned
    case encouraging
    case celebrating
    case waiting
    case hardMoment
}

// MARK: - Theme

struct AppPalette {
    let background: Color
    let card: Color
    let primaryText: Color
    let secondaryText: Color
    let accent: Color
    let blush: Color
    let divider: Color
    let destructive: Color
    let isNight: Bool

    static let day = AppPalette(
        background: Color(hex: "FFF7EF"),
        card: Color(hex: "FFFCF8"),
        primaryText: Color(hex: "2C211B"),
        secondaryText: Color(hex: "6F5F55"),
        accent: Color(hex: "EFA76A"),
        blush: Color(hex: "D98B83"),
        divider: Color(hex: "E8D8CB"),
        destructive: Color(hex: "A8443A"),
        isNight: false
    )

    static let night = AppPalette(
        background: Color(hex: "17120F"),
        card: Color(hex: "241B16"),
        primaryText: Color(hex: "F7EEE6"),
        secondaryText: Color(hex: "C1B2A7"),
        accent: Color(hex: "F0A05A"),
        blush: Color(hex: "D9827A"),
        divider: Color(hex: "3C2E27"),
        destructive: Color(hex: "EB8B82"),
        isNight: true
    )
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = AppPalette.day
}

extension EnvironmentValues {
    var palette: AppPalette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

struct ThemedRoot<Content: View>: View {
    let appearanceMode: AppearanceMode
    let content: Content
    @Environment(\.colorScheme) private var colorScheme

    init(appearanceMode: AppearanceMode, @ViewBuilder content: () -> Content) {
        self.appearanceMode = appearanceMode
        self.content = content()
    }

    private var palette: AppPalette {
        switch appearanceMode {
        case .system:
            return colorScheme == .dark ? .night : .day
        case .day:
            return .day
        case .night:
            return .night
        }
    }

    var body: some View {
        content
            .environment(\.palette, palette)
            .tint(palette.accent)
            .background(palette.background)
            .preferredColorScheme(preferredScheme)
    }

    private var preferredScheme: ColorScheme? {
        switch appearanceMode {
        case .system: nil
        case .day: .light
        case .night: .dark
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

// MARK: - Reusable UI

struct WarmScreen<Content: View>: View {
    @Environment(\.palette) private var palette
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            content
        }
    }
}

struct WarmCard<Content: View>: View {
    @Environment(\.palette) private var palette
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(palette.divider.opacity(0.7), lineWidth: 1)
            )
    }
}

struct PrimaryButton: View {
    @Environment(\.palette) private var palette
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(Color(hex: "2C211B"))
            .background(palette.accent)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    @Environment(\.palette) private var palette
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(palette.primaryText)
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ChoiceButton: View {
    @Environment(\.palette) private var palette
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 12)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.accent)
                }
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundStyle(palette.primaryText)
            .background(isSelected ? palette.accent.opacity(0.22) : palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? palette.accent : palette.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SectionTitle: View {
    @Environment(\.palette) private var palette
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundStyle(palette.primaryText)
                .lineSpacing(4)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CompanionCharacter: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let state: CompanionState
    var size: CGFloat = 132
    @State private var animate = false

    private var lift: CGFloat {
        switch state {
        case .celebrating: -8
        case .hardMoment: -4
        case .listening: 4
        case .concerned: 7
        default: 0
        }
    }

    private var scale: CGFloat {
        switch state {
        case .hardMoment: 1.18
        case .listening: 1.04
        case .encouraging: 1.03
        default: 1
        }
    }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(palette.isNight ? palette.accent.opacity(0.22) : Color.black.opacity(0.08))
                .frame(width: size * 0.72, height: size * 0.14)
                .offset(y: size * 0.42)

            if palette.isNight {
                Circle()
                    .fill(palette.accent.opacity(state == .hardMoment ? 0.24 : 0.14))
                    .frame(width: size * 1.45, height: size * 1.45)
                    .blur(radius: 24)
            }

            BlobShape()
                .fill(palette.isNight ? Color(hex: "C76E55") : Color(hex: "F0B082"))
                .frame(width: size * 0.76, height: size)
                .shadow(color: palette.accent.opacity(palette.isNight ? 0.28 : 0.14), radius: 18, x: 0, y: 9)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(palette.isNight ? 0.16 : 0.32))
                        .frame(width: size * 0.18)
                        .offset(x: -size * 0.18, y: size * 0.16)
                }

            face
                .offset(y: -size * 0.05)

            if state == .thinking {
                ThinkingDots(size: size)
                    .offset(y: -size * 0.46)
            }
        }
        .frame(width: size * 1.45, height: size * 1.45)
        .scaleEffect(reduceMotion ? scale : (animate ? scale : 1))
        .offset(y: reduceMotion ? 0 : (animate ? lift : 0))
        .opacity(reduceMotion && state != .resting ? 0.94 : 1)
        .animation(reduceMotion ? nil : .easeInOut(duration: state == .celebrating ? 0.75 : 1.8).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate = true }
    }

    private var face: some View {
        VStack(spacing: 12) {
            HStack(spacing: 22) {
                Eye(isConcerned: state == .concerned || state == .hardMoment)
                Eye(isConcerned: state == .concerned || state == .hardMoment)
            }
            Mouth(isSpeaking: state == .speaking, isConcerned: state == .concerned || state == .hardMoment)
        }
        .foregroundStyle(Color(hex: "3A241A"))
    }
}

struct Eye: View {
    let isConcerned: Bool

    var body: some View {
        Capsule()
            .fill(.primary.opacity(0.86))
            .frame(width: 9, height: isConcerned ? 5 : 11)
            .rotationEffect(.degrees(isConcerned ? -4 : 0))
    }
}

struct Mouth: View {
    let isSpeaking: Bool
    let isConcerned: Bool

    var body: some View {
        Capsule()
            .fill(.primary.opacity(0.7))
            .frame(width: isSpeaking ? 18 : 14, height: isConcerned ? 4 : 6)
            .opacity(isConcerned ? 0.55 : 0.75)
    }
}

struct ThinkingDots: View {
    @Environment(\.palette) private var palette
    let size: CGFloat

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(palette.accent.opacity(0.65 - Double(index) * 0.12))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(10)
        .background(palette.card.opacity(0.78))
        .clipShape(Capsule())
    }
}

struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.52, y: h * 0.05))
        path.addCurve(to: CGPoint(x: w * 0.89, y: h * 0.28), control1: CGPoint(x: w * 0.72, y: h * 0.03), control2: CGPoint(x: w * 0.88, y: h * 0.13))
        path.addCurve(to: CGPoint(x: w * 0.82, y: h * 0.78), control1: CGPoint(x: w * 0.93, y: h * 0.47), control2: CGPoint(x: w * 0.98, y: h * 0.68))
        path.addCurve(to: CGPoint(x: w * 0.38, y: h * 0.96), control1: CGPoint(x: w * 0.68, y: h * 0.91), control2: CGPoint(x: w * 0.49, y: h * 1.0))
        path.addCurve(to: CGPoint(x: w * 0.08, y: h * 0.64), control1: CGPoint(x: w * 0.16, y: h * 0.89), control2: CGPoint(x: w * 0.04, y: h * 0.78))
        path.addCurve(to: CGPoint(x: w * 0.14, y: h * 0.22), control1: CGPoint(x: w * 0.05, y: h * 0.45), control2: CGPoint(x: w * 0.01, y: h * 0.29))
        path.addCurve(to: CGPoint(x: w * 0.52, y: h * 0.05), control1: CGPoint(x: w * 0.25, y: h * 0.09), control2: CGPoint(x: w * 0.34, y: h * 0.04))
        return path
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @Environment(\.palette) private var palette
    @Binding var profile: AppProfile
    let complete: () -> Void
    @State private var step = 0

    private let relationshipTypes = ["My partner", "My ex", "Someone I was dating", "A situationship", "Someone I loved", "We were never officially together", "Something else"]
    private let durations = ["A few weeks", "A few months", "About a year", "Several years", "It's complicated"]
    private let endedByOptions = ["I did", "They did", "We both did", "It's complicated"]
    private let communicationOptions = ["No", "Sometimes", "Yes", "We're trying not to", "We have to stay in contact", "It's complicated"]
    private let contactGoals = ["Stop contacting them", "Keep contact limited", "Stop checking their social media", "Decide whether to respond", "Understand what happened", "Move on emotionally", "I don't know yet"]
    private let lastContactOptions = ["Today", "Yesterday", "Choose a date", "We're still in contact", "I don't remember"]
    private let hardBehaviorOptions = ["Text them", "Call them", "Check their profile", "Look through old messages", "Reply immediately", "Ask them to come back", "Blame myself", "Something else"]

    var body: some View {
        WarmScreen {
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        currentStep
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(palette.divider.opacity(0.75))
                Capsule()
                    .fill(palette.accent)
                    .frame(width: proxy.size.width * CGFloat(step + 1) / 14)
            }
        }
        .frame(height: 6)
    }

    @ViewBuilder
    private var currentStep: some View {
        switch step {
        case 0:
            landingStep
        case 1:
            textStep(title: "What should I call you?", placeholder: "Your name", text: $profile.userName, subtitle: "This helps your other self speak to you naturally.")
        case 2:
            textStep(title: "First, who are we getting over?", placeholder: "Their name", text: $profile.personName, subtitle: "This is saved as a person, not buried inside a chat.")
        case 3:
            singleChoiceStep(title: "What were they to you?", options: relationshipTypes, selection: $profile.relationshipType)
        case 4:
            singleChoiceStep(title: "How long were they part of your life?", options: durations, selection: $profile.duration)
        case 5:
            singleChoiceStep(title: "When did things end?", options: ["It hasn't completely ended", "I'm not sure", "Skip"], selection: $profile.endingStatus)
        case 6:
            singleChoiceStep(title: "Who ended it?", options: endedByOptions, selection: $profile.endedBy)
        case 7:
            singleChoiceStep(title: "Are you still talking?", options: communicationOptions, selection: $profile.contactStatus)
        case 8:
            multipleChoiceStep(title: "What are you trying to do right now?", options: contactGoals, selections: $profile.contactGoals)
        case 9:
            singleChoiceStep(title: "When did you last have contact?", options: lastContactOptions, selection: $profile.lastContact)
        case 10:
            storyStep(title: "Okay. I know who \(profile.rememberedPerson) is now.", prompt: "Tell me what happened.", text: $profile.story)
        case 11:
            storyStep(title: "What hurts the most right now?", prompt: "Say it plainly. You do not have to make it sound reasonable.", text: $profile.currentHurt)
        case 12:
            singleChoiceStep(title: "When it gets bad, what are you most likely to do?", options: hardBehaviorOptions, selection: $profile.hardBehavior)
        default:
            namingStep
        }
    }

    private var landingStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer(minLength: 18)
            Text("Heal Your Heart")
                .font(.system(size: 48, weight: .semibold, design: .serif))
                .foregroundStyle(palette.primaryText)
                .lineSpacing(4)
            Text("You Can't Make Them Love You...\nAnd That's Okay.")
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundStyle(palette.primaryText)
                .lineSpacing(5)
            Text("A warm place to get through the hard moments, remember what matters, and keep moving without turning your healing into homework.")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(palette.secondaryText)
                .lineSpacing(6)
            Text(HealYourHeartCopy.onboardingDisclosure)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(palette.secondaryText)
                .lineSpacing(4)
            HStack {
                Spacer()
                CompanionCharacter(state: .resting, size: 170)
                    .offset(y: 20)
                Spacer()
            }
        }
    }

    private func textStep(title: String, placeholder: String, text: Binding<String>, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionTitle(title: title, subtitle: subtitle)
            TextField(placeholder, text: text)
                .font(.system(size: 19, weight: .regular, design: .rounded))
                .textFieldStyle(.plain)
                .padding(18)
                .background(palette.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
        }
    }

    private func singleChoiceStep(title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionTitle(title: title)
            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selection.wrappedValue == option) {
                        selection.wrappedValue = option
                    }
                }
            }
        }
    }

    private func multipleChoiceStep(title: String, options: [String], selections: Binding<Set<String>>) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionTitle(title: title, subtitle: "Choose everything that fits right now.")
            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    ChoiceButton(title: option, isSelected: selections.wrappedValue.contains(option)) {
                        if selections.wrappedValue.contains(option) {
                            selections.wrappedValue.remove(option)
                        } else {
                            selections.wrappedValue.insert(option)
                        }
                    }
                }
            }
        }
    }

    private func storyStep(title: String, prompt: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            CompanionCharacter(state: .listening, size: 112)
                .frame(maxWidth: .infinity)
            SectionTitle(title: title, subtitle: prompt)
            TextEditor(text: text)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .scrollContentBackground(.hidden)
                .foregroundStyle(palette.primaryText)
                .padding(14)
                .frame(minHeight: 180)
                .background(palette.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
        }
    }

    private var namingStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            CompanionCharacter(state: .encouraging, size: 150)
                .frame(maxWidth: .infinity)
            SectionTitle(title: "Somewhere else, there's another you.", subtitle: "They know what this feels like. They remember what you tell them, and they're here when things get difficult.")
            Text("What should we call them?")
                .font(.system(size: 25, weight: .semibold, design: .serif))
                .foregroundStyle(palette.primaryText)
            TextField("Name your other self", text: $profile.companionName)
                .font(.system(size: 19, weight: .regular, design: .rounded))
                .padding(18)
                .background(palette.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
            if !profile.companionName.isEmpty {
                WarmCard {
                    Text("Hi. I'm \(profile.companionName).\nYou don't have to explain everything again. I'll remember.")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button {
                    withAnimation(.easeInOut) { step -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 52, height: 52)
                        .foregroundStyle(palette.primaryText)
                        .background(palette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(palette.divider, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            PrimaryButton(title: step == 0 ? "Start healing" : step == 13 ? "Open Home" : "Continue", systemImage: step == 0 ? "heart.fill" : "arrow.right") {
                withAnimation(.easeInOut) {
                    if step >= 13 {
                        if profile.companionName.isEmpty {
                            profile.companionName = "Mara"
                        }
                        complete()
                    } else {
                        step += 1
                    }
                }
            }
        }
    }
}

// MARK: - Main App

struct MainAppView: View {
    @Binding var profile: AppProfile
    @Binding var appearanceMode: String

    var body: some View {
        TabView {
            HomeView(profile: $profile, appearanceMode: $appearanceMode)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            JourneyView(profile: profile)
                .tabItem {
                    Label("Journey", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                }

            CompanionChatView(profile: profile)
                .tabItem {
                    Label("Talk", systemImage: "bubble.left.and.bubble.right.fill")
                }
        }
    }
}

struct HomeView: View {
    @Environment(\.palette) private var palette
    @AppStorage("storedChatMessages") private var storedChatMessages = ""
    @AppStorage("storedContactEvents") private var storedContactEvents = ""
    @Binding var profile: AppProfile
    @Binding var appearanceMode: String
    @State private var showingHardMoment = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            WarmScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        topSection
                        needYouButton
                        todaysJourney
                        if profile.shouldShowContactProgress {
                            contactProgress
                        }
                        recentConversation
                        phaseCard
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 28)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(palette.primaryText)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingHardMoment) {
                HardMomentView(profile: profile)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(profile: $profile, appearanceMode: $appearanceMode)
            }
        }
    }

    private var topSection: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Good evening, \(profile.displayName).")
                    .font(.system(size: 36, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.primaryText)
                    .lineSpacing(3)
                Text(profile.currentHurt.isEmpty ? "I'm here for the next small step." : "You told me this still hurts. We can take it slowly.")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(5)
            }
            Spacer(minLength: 6)
            CompanionCharacter(state: .resting, size: 104)
        }
    }

    private var needYouButton: some View {
        Button {
            showingHardMoment = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                Text("I need you")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
            }
            .frame(minHeight: 70)
            .padding(.horizontal, 20)
            .foregroundStyle(Color(hex: "2C211B"))
            .background(palette.accent)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var todaysJourney: some View {
        WarmCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("DAY 14")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                Text("The Wave of the Urge")
                    .font(.system(size: 25, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.primaryText)
                Text("Learn what an urge is doing before you act on it.")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(5)
                PrimaryButton(title: "Continue", systemImage: "arrow.right") { }
            }
        }
    }

    private var contactProgress: some View {
        WarmCard {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(contactProgressDays)")
                    .font(.system(size: 60, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.primaryText)
                Text("days\n\(profile.contactProgressLabel)")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(5)
                Spacer()
            }
        }
    }

    private var contactProgressDays: Int {
        let confirmedEvents = (LocalPersistence.decode([ContactEvent].self, from: storedContactEvents) ?? [])
            .filter { $0.confirmedReset }
            .sorted { $0.createdAt > $1.createdAt }

        if let latestReset = confirmedEvents.first?.createdAt {
            return Calendar.current.dateComponents([.day], from: latestReset, to: Date()).day ?? 0
        }

        switch profile.lastContact {
        case "Today", "We're still in contact":
            return 0
        case "Yesterday":
            return 1
        default:
            return profile.shouldShowContactProgress ? 1 : 0
        }
    }

    private var recentConversation: some View {
        WarmCard {
            HStack(spacing: 14) {
                CompanionCharacter(state: .waiting, size: 60)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Continue with \(profile.companionDisplayName)")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(palette.primaryText)
                    Text(recentConversationSubtitle)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                }
                Spacer()
            }
        }
    }

    private var recentConversationSubtitle: String {
        let savedMessages = LocalPersistence.decode([ChatBubbleModel].self, from: storedChatMessages) ?? []
        if savedMessages.contains(where: { $0.role == .user && !$0.isDeleted }) {
            return "Pick up from your saved conversation about \(profile.rememberedPerson)."
        }
        return "Start with what is happening right now."
    }

    private var phaseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CURRENT PHASE")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(palette.secondaryText)
            Text("Cut Off and Understand")
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(palette.primaryText)
            ProgressView(value: 0.42)
                .tint(palette.accent)
            Text("42% of your current Journey")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(palette.secondaryText)
        }
        .padding(.vertical, 8)
    }
}

struct JourneyView: View {
    @Environment(\.palette) private var palette
    @AppStorage("completedJourneyDays") private var completedJourneyDays = "1,2,3,8"
    let profile: AppProfile
    @State private var selectedLength = 30
    @State private var selectedDay: JourneyDay?

    private let days = [
        JourneyDay(number: 1, title: "Your Fragile Moments", phase: "Stabilize", state: .completed, lesson: "Your nervous system is trying to protect you by making everything feel urgent.", action: "Put one glass of water and one simple food choice within reach.", checkIn: "What part of today felt most fragile?"),
        JourneyDay(number: 2, title: "Breathing Out", phase: "Stabilize", state: .completed, lesson: "Relief often starts by slowing the body before solving the story.", action: "Try four slow exhales before opening any old messages.", checkIn: "Did your body soften even a little?"),
        JourneyDay(number: 3, title: "Taking Stock of the Storm", phase: "Stabilize", state: .completed, lesson: "A storm is easier to survive when you can name what is happening inside it.", action: "Name one feeling, one fact, and one thing you do not know yet.", checkIn: "Which part is fact, and which part is fear?"),
        JourneyDay(number: 8, title: "Why the Silence", phase: "Cut Off and Understand", state: .completed, lesson: "Silence can feel like an answer, a punishment, or an invitation to chase. It may be none of those.", action: "Do not use silence as evidence of your worth today.", checkIn: "What meaning are you adding to the silence?"),
        JourneyDay(number: 14, title: "The Wave of the Urge", phase: "Cut Off and Understand", state: .current, lesson: "An urge rises, peaks, and falls. It asks for action, but it is not the same as a decision.", action: "Delay the next contact impulse by ten minutes and stay with your companion while it passes.", checkIn: "What outcome did the urge promise you?"),
        JourneyDay(number: 15, title: "The Version You Miss", phase: "Untangle the Story", state: .upcoming, lesson: "Sometimes you miss a real person. Sometimes you miss the version of the relationship your mind edits together.", action: "Compare one warm memory with one fact you usually skip.", checkIn: "What changed when both were allowed in the room?"),
        JourneyDay(number: 20, title: "What Actually Happened", phase: "Untangle the Story", state: .upcoming, lesson: "Healing asks for the whole story: what was beautiful, what was painful, and what kept repeating.", action: "Tell your companion one pattern you do not want to normalize again.", checkIn: "What did you protect by telling the fuller truth?"),
        JourneyDay(number: 28, title: "You Don't Need One More Answer", phase: "Untangle the Story", state: .locked, lesson: "Some answers would only create another question. Closure can start before certainty arrives.", action: "Write no letter. Send no proof. Choose one action that belongs only to your life.", checkIn: "What would you do tonight if no answer came?")
    ]

    var body: some View {
        NavigationStack {
            WarmScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        SectionTitle(title: "Your Journey", subtitle: "A warm path through the first difficult stretch. No journal. No homework wall.")

                        Picker("Journey length", selection: $selectedLength) {
                            Text("30").tag(30)
                            Text("60").tag(60)
                            Text("90").tag(90)
                        }
                        .pickerStyle(.segmented)

                        WarmCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("\(progressPercent)%")
                                    .font(.system(size: 58, weight: .semibold, design: .serif))
                                    .foregroundStyle(palette.primaryText)
                                Text("of your current Journey")
                                    .font(.system(size: 17, weight: .regular, design: .rounded))
                                    .foregroundStyle(palette.secondaryText)
                                ProgressView(value: Double(completedNumbers.count), total: Double(selectedLength))
                                    .tint(palette.accent)
                            }
                        }

                        VStack(spacing: 0) {
                            ForEach(days) { day in
                                Button {
                                    selectedDay = resolvedDay(day)
                                } label: {
                                    JourneyRow(day: resolvedDay(day))
                                }
                                .buttonStyle(.plain)
                                if day.id != days.last?.id {
                                    Rectangle()
                                        .fill(palette.divider)
                                        .frame(width: 1, height: 20)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 26)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 28)
                }
            }
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedDay) { day in
                JourneyDayDetail(day: day, profile: profile) {
                    markCompleted(day.number)
                }
            }
        }
    }

    private var completedNumbers: Set<Int> {
        Set(completedJourneyDays.split(separator: ",").compactMap { Int($0) })
    }

    private var progressPercent: Int {
        Int((Double(completedNumbers.count) / Double(selectedLength) * 100).rounded())
    }

    private func resolvedDay(_ day: JourneyDay) -> JourneyDay {
        if completedNumbers.contains(day.number) {
            return day.replacingState(.completed)
        }
        if day.number == 14 {
            return day.replacingState(.current)
        }
        return day
    }

    private func markCompleted(_ number: Int) {
        var completed = completedNumbers
        completed.insert(number)
        completedJourneyDays = completed.sorted().map(String.init).joined(separator: ",")
        selectedDay = selectedDay?.replacingState(.completed)
    }
}

struct JourneyDay: Identifiable, Equatable {
    enum State {
        case completed
        case current
        case upcoming
        case locked
    }

    let id = UUID()
    let number: Int
    let title: String
    let phase: String
    let state: State
    let lesson: String
    let action: String
    let checkIn: String

    func replacingState(_ newState: State) -> JourneyDay {
        JourneyDay(number: number, title: title, phase: phase, state: newState, lesson: lesson, action: action, checkIn: checkIn)
    }
}

struct JourneyRow: View {
    @Environment(\.palette) private var palette
    let day: JourneyDay

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(circleFill)
                    .frame(width: 52, height: 52)
                if day.state == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "2C211B"))
                } else if day.state == .locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.secondaryText)
                } else {
                    Text("\(day.number)")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(day.state == .current ? Color(hex: "2C211B") : palette.primaryText)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(day.state == .current ? "DAY \(day.number)" : day.phase.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                Text(day.title)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.primaryText)
                Text(rowSubtitle)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(4)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private var circleFill: Color {
        switch day.state {
        case .completed, .current: palette.accent
        case .upcoming: palette.card
        case .locked: palette.divider.opacity(0.45)
        }
    }

    private var rowSubtitle: String {
        switch day.state {
        case .completed: "Completed"
        case .current: "Learn what an urge is doing before you act on it."
        case .upcoming: "Coming up"
        case .locked: "Unlocks as your path continues"
        }
    }
}

struct JourneyDayDetail: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    let day: JourneyDay
    let profile: AppProfile
    let markCompleted: () -> Void

    var body: some View {
        NavigationStack {
            WarmScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(alignment: .center, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DAY \(day.number)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(palette.secondaryText)
                                Text(day.title)
                                    .font(.system(size: 36, weight: .semibold, design: .serif))
                                    .foregroundStyle(palette.primaryText)
                                    .lineSpacing(4)
                            }
                            Spacer()
                            CompanionCharacter(state: day.state == .completed ? .celebrating : .encouraging, size: 86)
                        }

                        WarmCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Short lesson")
                                    .font(.system(size: 21, weight: .semibold, design: .serif))
                                    .foregroundStyle(palette.primaryText)
                                Text(day.lesson)
                                    .font(.system(size: 18, weight: .regular, design: .rounded))
                                    .foregroundStyle(palette.secondaryText)
                                    .lineSpacing(5)
                            }
                        }

                        WarmCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("One practical action")
                                    .font(.system(size: 21, weight: .semibold, design: .serif))
                                    .foregroundStyle(palette.primaryText)
                                Text(day.action)
                                    .font(.system(size: 18, weight: .regular, design: .rounded))
                                    .foregroundStyle(palette.secondaryText)
                                    .lineSpacing(5)
                            }
                        }

                        WarmCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Simple check-in")
                                    .font(.system(size: 21, weight: .semibold, design: .serif))
                                    .foregroundStyle(palette.primaryText)
                                Text(day.checkIn)
                                    .font(.system(size: 18, weight: .regular, design: .rounded))
                                    .foregroundStyle(palette.secondaryText)
                                    .lineSpacing(5)
                            }
                        }

                        Text("\(profile.companionDisplayName) can talk this through with you when you need it.")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                            .lineSpacing(5)

                        PrimaryButton(title: day.state == .completed ? "Completed" : "Mark complete", systemImage: "checkmark.circle.fill") {
                            markCompleted()
                            dismiss()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 30)
                }
            }
            .navigationTitle("Day \(day.number)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Companion Chat

struct CompanionChatView: View {
    @Environment(\.palette) private var palette
    @AppStorage("storedChatMessages") private var storedChatMessages = ""
    @AppStorage("storedMemoryItems") private var storedMemoryItems = ""
    let profile: AppProfile
    @State private var mode: TalkMode = .chat
    @State private var draft = ""
    @State private var messages: [ChatBubbleModel] = [
        ChatBubbleModel(role: .companion, text: "Hi. I am here. You do not have to explain everything again.")
    ]
    @State private var memories: [MemoryRecord] = []

    var body: some View {
        NavigationStack {
            WarmScreen {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                        .padding(.bottom, 14)

                    Picker("Mode", selection: $mode) {
                        Text("Chat").tag(TalkMode.chat)
                        Text("Talk").tag(TalkMode.talk)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)

                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(messages) { message in
                                    ChatBubble(
                                        message: message,
                                        companionName: profile.companionDisplayName,
                                        togglePinned: {
                                            togglePinned(message)
                                        },
                                        deleteMessage: {
                                            deleteMessage(message)
                                        }
                                    )
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                        }
                        .onChange(of: messages.count) { _, _ in
                            if let last = messages.last {
                                withAnimation(.easeOut) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    if mode == .talk {
                        TalkControls(profile: profile, draft: $draft, send: sendMessage)
                    } else {
                        ChatComposer(draft: $draft, send: sendMessage)
                    }
                }
            }
            .navigationTitle("Talk")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear(perform: loadMessages)
        .onAppear(perform: loadMemories)
        .onChange(of: messages) { _, newValue in
            storedChatMessages = LocalPersistence.encode(newValue)
        }
        .onChange(of: memories) { _, newValue in
            storedMemoryItems = LocalPersistence.encode(newValue)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            CompanionCharacter(state: mode == .talk ? .listening : .waiting, size: 78)
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.companionDisplayName)
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.primaryText)
                Text("Your other self")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
            }
            Spacer()
        }
    }

    private func sendMessage() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let userMessage = ChatBubbleModel(role: .user, text: trimmed, sourceMode: mode == .talk ? "voice" : "text")
        messages.append(userMessage)
        rememberFacts(from: userMessage)
        draft = ""
        let response = LocalCompanionService().send(message: trimmed, context: CompanionContext(profile: profile, recentMessages: messages, memories: memories))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            messages.append(ChatBubbleModel(role: .companion, text: response.reply, sourceMode: mode == .talk ? "voice" : "text"))
            if mode == .talk {
                SpeechPlaybackEngine.shared.speak(response.reply)
            }
        }
    }

    private func loadMessages() {
        guard let decoded = LocalPersistence.decode([ChatBubbleModel].self, from: storedChatMessages), !decoded.isEmpty else {
            messages = [
                ChatBubbleModel(role: .companion, text: "Hi. I am \(profile.companionDisplayName). You do not have to explain everything again. I'll remember what matters here.")
            ]
            return
        }
        messages = decoded.filter { !$0.isDeleted }
    }

    private func loadMemories() {
        memories = LocalPersistence.decode([MemoryRecord].self, from: storedMemoryItems) ?? []
    }

    private func rememberFacts(from message: ChatBubbleModel) {
        let extracted = MemoryExtractor.extract(from: message, profile: profile)
        for memory in extracted {
            if let index = memories.firstIndex(where: { $0.category == memory.category && $0.subject == memory.subject }) {
                memories[index].content = memory.content
                memories[index].sourceMessageIDs = Array(Set(memories[index].sourceMessageIDs + memory.sourceMessageIDs))
                memories[index].updatedAt = Date()
            } else {
                memories.append(memory)
            }
        }
    }

    private func togglePinned(_ message: ChatBubbleModel) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
        messages[index].isPinned.toggle()
    }

    private func deleteMessage(_ message: ChatBubbleModel) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
        messages[index].isDeleted = true
        messages.removeAll { $0.isDeleted }
    }
}

enum TalkMode {
    case chat
    case talk
}

struct ChatBubbleModel: Identifiable, Codable, Equatable {
    enum Role: String, Codable {
        case user
        case companion
    }

    var id = UUID()
    let role: Role
    let text: String
    var sourceMode = "text"
    var isPinned = false
    var isDeleted = false
}

struct CompanionContext {
    let profile: AppProfile
    let recentMessages: [ChatBubbleModel]
    let memories: [MemoryRecord]

    var knownFacts: [String] {
        var facts: [String] = []
        if !profile.personName.isEmpty {
            facts.append("The person being recovered from is \(profile.personName).")
        }
        if !profile.relationshipType.isEmpty {
            facts.append("Relationship type: \(profile.relationshipType).")
        }
        if !profile.contactStatus.isEmpty {
            facts.append("Current communication: \(profile.contactStatus).")
        }
        if !profile.contactGoals.isEmpty {
            facts.append("Current goals: \(profile.contactGoals.sorted().joined(separator: ", ")).")
        }
        if !profile.currentHurt.isEmpty {
            facts.append("What currently hurts: \(profile.currentHurt).")
        }
        if !profile.hardBehavior.isEmpty {
            facts.append("Likely hard-moment behavior: \(profile.hardBehavior).")
        }
        return facts
    }
}

struct CompanionReply {
    let reply: String
    let suggestedAction: String?
}

protocol CompanionService {
    func send(message: String, context: CompanionContext) -> CompanionReply
}

protocol SpeechPlaybackService {
    func speak(_ text: String)
    func stop()
}

final class SpeechPlaybackEngine: NSObject, SpeechPlaybackService, AVSpeechSynthesizerDelegate {
    static let shared = SpeechPlaybackEngine()
    private let synthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 0.95
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}

struct LocalCompanionService: CompanionService {
    func send(message: String, context: CompanionContext) -> CompanionReply {
        let lowercased = message.lowercased()
        let personName = context.profile.rememberedPerson
        let relevantMemory = context.memories
            .filter { memory in
                lowercased.contains(memory.subject.lowercased()) ||
                memory.sourceMessageIDs.contains { id in
                    context.recentMessages.suffix(8).contains { $0.id.uuidString == id }
                }
            }
            .sorted { $0.importance > $1.importance }
            .first

        if containsAny(lowercased, words: ["kill myself", "end my life", "hurt myself", "hurt them", "suicide", "can't stay safe"]) {
            return CompanionReply(
                reply: "This is bigger than a breakup moment. Please contact emergency services now if anyone is in immediate danger, or reach a trusted person who can stay with you. I can stay here, but human help needs to come first.",
                suggestedAction: "safety"
            )
        }

        if containsAny(lowercased, words: ["text", "call", "reach out", "message"]) {
            let boundary = context.profile.contactGoals.isEmpty ? "the boundary you want" : context.profile.contactGoals.sorted().joined(separator: ", ")
            return CompanionReply(
                reply: "Pause before you act. You said your current goal is \(boundary). What outcome are you hoping contact with \(personName) will give you tonight?",
                suggestedAction: "delay_timer"
            )
        }

        if containsAny(lowercased, words: ["liked", "story", "profile", "social", "seen"]) {
            return CompanionReply(
                reply: "That is a real trigger. What it literally proves may be small, and what it touches in you may be much bigger. What do you know for sure, and what are you afraid it means?",
                suggestedAction: "facts_hopes_fears"
            )
        }

        if containsAny(lowercased, words: ["miss", "lonely", "want them", "need them"]) {
            if !context.profile.currentHurt.isEmpty {
                return CompanionReply(
                    reply: "This connects to what you said hurts most: \(context.profile.currentHurt). I will not talk you out of missing \(personName). I do want to ask: are you missing the whole reality, or the version you keep replaying?",
                    suggestedAction: nil
                )
            }
            return CompanionReply(
                reply: "Missing \(personName) does not mean contacting them is the next right move. Which part are you missing right now: comfort, certainty, touch, apology, or the old routine?",
                suggestedAction: nil
            )
        }

        if containsAny(lowercased, words: ["slipped", "replied", "checked", "saw them"]) {
            return CompanionReply(
                reply: "This does not erase your progress. Tell me exactly what happened first, then we can decide whether anything about the streak or contact plan actually needs to change.",
                suggestedAction: "slip_review"
            )
        }

        if let relevantMemory {
            return CompanionReply(
                reply: "I am using something you actually told me: \(relevantMemory.content) Given that, what is the next action that protects you for the next ten minutes?",
                suggestedAction: nil
            )
        }

        if containsAny(lowercased, words: ["why", "what if", "do they", "does he", "does she"]) {
            return CompanionReply(
                reply: "We can separate this into facts, hopes, and fears. I cannot know what \(personName) intends without direct evidence. What is the clearest fact you have?",
                suggestedAction: nil
            )
        }

        if context.profile.personName.isEmpty {
            return CompanionReply(
                reply: "Stay with this for one more sentence. What part feels most urgent right now?",
                suggestedAction: nil
            )
        }

        return CompanionReply(
            reply: "I know this is connected to \(personName). Use one sentence for the fact, and one sentence for the meaning your mind is adding to it.",
            suggestedAction: nil
        )
    }

    private func containsAny(_ text: String, words: [String]) -> Bool {
        words.contains { text.contains($0) }
    }
}

struct ChatBubble: View {
    @Environment(\.palette) private var palette
    let message: ChatBubbleModel
    let companionName: String
    let togglePinned: () -> Void
    let deleteMessage: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .companion {
                CompanionCharacter(state: .speaking, size: 44)
            } else {
                Spacer(minLength: 42)
            }

            VStack(alignment: .leading, spacing: 6) {
                if message.role == .companion {
                    Text(companionName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                }
                Text(message.text)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(message.role == .user ? Color(hex: "2C211B") : palette.primaryText)
                    .lineSpacing(4)
            }
            .padding(14)
            .background(message.role == .user ? palette.accent : palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .frame(maxWidth: 300, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .companion {
                Spacer(minLength: 42)
            }
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = message.text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            Button(action: togglePinned) {
                Label(message.isPinned ? "Unmark important" : "Mark important", systemImage: message.isPinned ? "pin.slash" : "pin")
            }

            Button(action: togglePinned) {
                Label(message.isPinned ? "Forget this" : "Remember this", systemImage: message.isPinned ? "trash" : "brain.head.profile")
            }

            Button(role: .destructive, action: deleteMessage) {
                Label("Delete message", systemImage: "trash")
            }
        }
    }
}

struct ChatComposer: View {
    @Environment(\.palette) private var palette
    @Binding var draft: String
    let send: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("Say what happened", text: $draft, axis: .vertical)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .lineLimit(1...4)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(palette.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(palette.accent)
            }
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(palette.background)
    }
}

struct TalkControls: View {
    @Environment(\.palette) private var palette
    let profile: AppProfile
    @Binding var draft: String
    let send: () -> Void
    @State private var isRecording = false
    @State private var speechStatus = "Tap the microphone to speak."
    @State private var speechService = AppleSpeechRecognitionService()

    var body: some View {
        VStack(spacing: 12) {
            Text(speechStatus)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(palette.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Live transcript appears here", text: $draft, axis: .vertical)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .lineLimit(1...3)
                .padding(16)
                .background(palette.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )

            HStack(spacing: 12) {
                Button {
                    Task {
                        if isRecording {
                            await stopRecording()
                        } else {
                            await startRecording()
                        }
                    }
                } label: {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .frame(width: 58, height: 58)
                        .foregroundStyle(Color(hex: "2C211B"))
                        .background(isRecording ? palette.blush : palette.accent)
                        .clipShape(Circle())
                }
                .accessibilityLabel(isRecording ? "Stop recording" : "Record")

                SecondaryButton(title: "Send transcript", systemImage: "arrow.up") {
                    isRecording = false
                    speechService.cancelRecording()
                    send()
                }
            }

            Button {
                SpeechPlaybackEngine.shared.stop()
            } label: {
                Label("Stop voice", systemImage: "stop.circle")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(palette.background)
    }

    private func startRecording() async {
        do {
            draft = ""
            speechStatus = "Listening..."
            let contextualStrings = [
                profile.displayName,
                profile.rememberedPerson,
                profile.companionDisplayName
            ].filter { !$0.isEmpty && $0 != "there" && $0 != "them" }
            try await speechService.startRecording(contextualStrings: contextualStrings) { transcript in
                draft = transcript
            }
            isRecording = true
        } catch {
            isRecording = false
            speechStatus = error.localizedDescription
        }
    }

    private func stopRecording() async {
        do {
            let transcript = try await speechService.stopRecording()
            draft = transcript
            speechStatus = "Transcript ready. You can edit it before sending."
        } catch {
            speechStatus = error.localizedDescription
        }
        isRecording = false
    }
}

// MARK: - Hard Moment

struct HardMomentView: View {
    @Environment(\.palette) private var palette
    @AppStorage("storedContactEvents") private var storedContactEvents = ""
    let profile: AppProfile
    @State private var path: HardMomentPath?
    @State private var urgeStrength = 5.0
    @State private var pastedMessage = ""
    @State private var slipDetails = ""
    @State private var contactEvents: [ContactEvent] = []
    @State private var selectedReachAction = ""
    @State private var selectedContactResponse = ""
    @State private var timerRemaining = 0
    @State private var timerRunning = false
    @State private var slipConfirmed = false

    var body: some View {
        WarmScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CompanionCharacter(state: .hardMoment, size: 178)
                        .frame(maxWidth: .infinity)
                    SectionTitle(title: "I'm here. What happened?")

                    if let path {
                        flow(for: path)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(HardMomentPath.allCases) { option in
                                ChoiceButton(title: option.title, isSelected: false) {
                                    withAnimation(.easeInOut) { path = option }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 34)
            }
        }
        .onAppear(perform: loadContactEvents)
        .onChange(of: contactEvents) { _, newValue in
            storedContactEvents = LocalPersistence.encode(newValue)
        }
        .task(id: timerRunning) {
            await runDelayTimer()
        }
    }

    @ViewBuilder
    private func flow(for path: HardMomentPath) -> some View {
        switch path {
        case .reachingOut:
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle(title: "What are you about to do?", subtitle: "We are slowing the decision down, not shaming it.")
                ForEach(["Text them", "Call them", "Check their profile", "Look at old messages", "Go somewhere they might be", "Something else"], id: \.self) { item in
                    ChoiceButton(title: item, isSelected: selectedReachAction == item) {
                        selectedReachAction = item
                    }
                }
                Text("How strong is the urge right now?")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.primaryText)
                HStack {
                    Text("0")
                    Slider(value: $urgeStrength, in: 0...10, step: 1)
                    Text("10")
                }
                .foregroundStyle(palette.secondaryText)
                WarmCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Before you act, wait ten minutes. Name the outcome you want, then ask whether contacting \(profile.rememberedPerson) usually gives you that outcome or just restarts the ache.")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.primaryText)
                            .lineSpacing(5)
                        if timerRemaining > 0 {
                            Text(formattedTimer)
                                .font(.system(size: 48, weight: .semibold, design: .serif))
                                .foregroundStyle(palette.primaryText)
                        }
                    }
                }
                PrimaryButton(title: timerRunning ? "Delay running" : "Start a 10 minute delay", systemImage: "timer") {
                    timerRemaining = 600
                    timerRunning = true
                    if !selectedReachAction.isEmpty {
                        contactEvents.append(ContactEvent(kind: "urge", detail: selectedReachAction, confirmedReset: false))
                    }
                }
            }
        case .contactedMe:
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle(title: "Paste what they sent.", subtitle: "We will separate what it says from what you hope it means.")
                TextEditor(text: $pastedMessage)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .padding(14)
                    .frame(minHeight: 150)
                    .background(palette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                WarmCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Possible next actions")
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(palette.primaryText)
                        Text("Do not reply, wait before replying, draft a response, set a boundary, ask one clear question, or keep talking before deciding.")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                            .lineSpacing(5)
                    }
                }
                VStack(spacing: 10) {
                    ForEach(["Don't reply", "Wait before replying", "Draft a response", "Set a boundary", "Ask one clear question", "Keep talking before deciding"], id: \.self) { item in
                        ChoiceButton(title: item, isSelected: selectedContactResponse == item) {
                            selectedContactResponse = item
                        }
                    }
                }
                if !selectedContactResponse.isEmpty {
                    WarmCard {
                        Text(contactResponseGuidance)
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.primaryText)
                            .lineSpacing(5)
                    }
                }
                PrimaryButton(title: "Save this contact event", systemImage: "tray.and.arrow.down") {
                    let detail = pastedMessage.isEmpty ? "They contacted me" : pastedMessage
                    contactEvents.append(ContactEvent(kind: "incoming_contact", detail: "\(detail)\nAction considered: \(selectedContactResponse)", confirmedReset: false))
                }
            }
        case .slipped:
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle(title: "What happened?", subtitle: "This changes the streak only after you confirm it. It does not erase what you learned.")
                TextEditor(text: $slipDetails)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .padding(14)
                    .frame(minHeight: 150)
                    .background(palette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                if slipConfirmed {
                    WarmCard {
                        Text("Confirmed. This can restart the streak, but Journey progress stays intact.")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.primaryText)
                            .lineSpacing(5)
                    }
                }
                PrimaryButton(title: "Confirm contact event", systemImage: "checkmark.circle") {
                    let detail = slipDetails.isEmpty ? "User confirmed a slip" : slipDetails
                    contactEvents.append(ContactEvent(kind: "slip", detail: detail, confirmedReset: true))
                    slipConfirmed = true
                }
            }
        case .somethingElse:
            WarmCard {
                Text("Tell me the part that feels too much right now. One sentence is enough.")
                    .font(.system(size: 19, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                    .lineSpacing(5)
            }
        case .notSafe:
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle(title: "Human help comes first.", subtitle: "If you or someone else may be in immediate danger, contact emergency services now or reach a trusted person who can stay with you.")
                WarmCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Right now")
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(palette.primaryText)
                        Text("Move away from anything you could use to hurt yourself or someone else. Call emergency services if danger is immediate. If you can, send one direct message to a trusted person: I am not safe alone right now. Can you stay with me or call me?")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                            .lineSpacing(5)
                    }
                }
                PrimaryButton(title: "Call emergency services", systemImage: "phone.fill") {
                    if let url = URL(string: "tel://911") {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    private var formattedTimer: String {
        let minutes = timerRemaining / 60
        let seconds = timerRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var contactResponseGuidance: String {
        switch selectedContactResponse {
        case "Don't reply":
            return "No reply is a response. You do not need to convert their message into an obligation."
        case "Wait before replying":
            return "Waiting protects you from answering from adrenaline. Give your body time to come down before deciding."
        case "Draft a response":
            return "Draft for clarity, not persuasion. Say only what protects your actual goal."
        case "Set a boundary":
            return "A boundary should be short, practical, and about what you will do next."
        case "Ask one clear question":
            return "Ask only if the answer would change your next action. Do not ask a question just to keep the thread alive."
        default:
            return "You can keep talking before deciding. Urgency is not the same as instruction."
        }
    }

    private func loadContactEvents() {
        contactEvents = LocalPersistence.decode([ContactEvent].self, from: storedContactEvents) ?? []
    }

    private func runDelayTimer() async {
        guard timerRunning else { return }
        while timerRemaining > 0 && timerRunning {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            timerRemaining -= 1
        }
        timerRunning = false
    }
}

enum HardMomentPath: String, CaseIterable, Identifiable {
    case reachingOut
    case contactedMe
    case slipped
    case somethingElse
    case notSafe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reachingOut: "I feel like reaching out"
        case .contactedMe: "They contacted me"
        case .slipped: "I slipped"
        case .somethingElse: "Something else"
        case .notSafe: "I might not be safe"
        }
    }
}

struct ContactEvent: Identifiable, Codable, Equatable {
    var id = UUID()
    let kind: String
    let detail: String
    let confirmedReset: Bool
    var createdAt = Date()
}

struct ContactEventRow: View {
    @Environment(\.palette) private var palette
    let event: ContactEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(eventTitle, systemImage: event.confirmedReset ? "arrow.counterclockwise.circle.fill" : "clock.badge.checkmark")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(event.confirmedReset ? palette.destructive : palette.primaryText)
                Spacer()
                Text(event.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
            }
            Text(event.detail)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(palette.secondaryText)
                .lineLimit(3)
                .lineSpacing(3)
        }
        .padding(.vertical, 8)
    }

    private var eventTitle: String {
        switch event.kind {
        case "urge": "Urge delayed"
        case "incoming_contact": "They contacted me"
        case "slip": "Confirmed slip"
        default: "Contact event"
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @AppStorage("storedMemoryItems") private var storedMemoryItems = ""
    @AppStorage("storedChatMessages") private var storedChatMessages = ""
    @AppStorage("storedContactEvents") private var storedContactEvents = ""
    @AppStorage("storedProfile") private var storedProfile = ""
    @AppStorage("storedOnboardingCompleted") private var storedOnboardingCompleted = false
    @AppStorage("completedJourneyDays") private var completedJourneyDays = "1,2,3,8"
    @Binding var profile: AppProfile
    @Binding var appearanceMode: String
    @State private var memories: [MemoryRecord] = []
    @State private var memorySearch = ""

    var body: some View {
        NavigationStack {
            WarmScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        SectionTitle(title: "Settings", subtitle: "Responses are AI-generated. Your history and memories are designed to stay under your control.")

                        WarmCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Appearance")
                                    .font(.system(size: 22, weight: .semibold, design: .serif))
                                    .foregroundStyle(palette.primaryText)
                                Picker("Appearance", selection: $appearanceMode) {
                                    ForEach(AppearanceMode.allCases) { mode in
                                        Text(mode.label).tag(mode.rawValue)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        WarmCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Companion name")
                                    .font(.system(size: 22, weight: .semibold, design: .serif))
                                    .foregroundStyle(palette.primaryText)
                                TextField("Name your other self", text: $profile.companionName)
                                    .font(.system(size: 17, weight: .regular, design: .rounded))
                                    .padding(14)
                                    .background(palette.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }

                        WarmCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("What \(profile.companionDisplayName) remembers")
                                    .font(.system(size: 22, weight: .semibold, design: .serif))
                                    .foregroundStyle(palette.primaryText)
                                TextField("Search memories", text: $memorySearch)
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .padding(12)
                                    .background(palette.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                ForEach(filteredMemories) { memory in
                                    EditableMemoryRow(
                                        memory: memory,
                                        update: updateMemory,
                                        delete: deleteMemory
                                    )
                                }
                                Divider().background(palette.divider)
                                Button("Export data") {
                                    exportLocalData()
                                }
                                Button("Delete conversation history", role: .destructive) {
                                    storedChatMessages = ""
                                }
                                Button("Clear all memories", role: .destructive) {
                                    memories.removeAll()
                                }
                                Button("Delete all local app data", role: .destructive) {
                                    clearAllLocalData()
                                }
                            }
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                        }

                        WarmCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Contact events")
                                    .font(.system(size: 22, weight: .semibold, design: .serif))
                                    .foregroundStyle(palette.primaryText)
                                if contactEvents.isEmpty {
                                    Text("No contact events have been saved yet.")
                                        .foregroundStyle(palette.secondaryText)
                                } else {
                                    ForEach(contactEvents.prefix(6)) { event in
                                        ContactEventRow(event: event)
                                    }
                                }
                                Button("Clear contact-event history", role: .destructive) {
                                    storedContactEvents = ""
                                }
                            }
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                        }

                        WarmCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Privacy and safety")
                                    .font(.system(size: 22, weight: .semibold, design: .serif))
                                    .foregroundStyle(palette.primaryText)
                                Text(HealYourHeartCopy.privacySummary)
                                    .foregroundStyle(palette.secondaryText)
                                    .lineSpacing(5)
                                Text(HealYourHeartCopy.productionPrivacyRequirement)
                                    .foregroundStyle(palette.secondaryText)
                                    .lineSpacing(5)
                                Text(HealYourHeartCopy.safetySummary)
                                    .foregroundStyle(palette.destructive)
                                    .lineSpacing(5)
                            }
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 28)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadMemories)
            .onChange(of: memories) { _, newValue in
                storedMemoryItems = LocalPersistence.encode(newValue)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var filteredMemories: [MemoryRecord] {
        guard !memorySearch.isEmpty else { return memories }
        return memories.filter {
            $0.subject.localizedCaseInsensitiveContains(memorySearch) ||
            $0.content.localizedCaseInsensitiveContains(memorySearch) ||
            $0.category.localizedCaseInsensitiveContains(memorySearch)
        }
    }

    private var contactEvents: [ContactEvent] {
        (LocalPersistence.decode([ContactEvent].self, from: storedContactEvents) ?? [])
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func loadMemories() {
        if let decoded = LocalPersistence.decode([MemoryRecord].self, from: storedMemoryItems), !decoded.isEmpty {
            memories = decoded
            return
        }

        var seeded: [MemoryRecord] = []
        if !profile.personName.isEmpty {
            seeded.append(MemoryRecord(category: "person information", subject: profile.personName, content: "User is recovering from attachment to \(profile.personName).", isPinned: true))
        }
        if !profile.contactGoals.isEmpty {
            seeded.append(MemoryRecord(category: "boundary", subject: "Contact goal", content: profile.contactGoals.sorted().joined(separator: ", "), isPinned: true))
        }
        if !profile.currentHurt.isEmpty {
            seeded.append(MemoryRecord(category: "current hurt", subject: "What hurts most", content: profile.currentHurt, isPinned: false))
        }
        if !profile.hardBehavior.isEmpty {
            seeded.append(MemoryRecord(category: "feared behavior", subject: "Hard moment behavior", content: profile.hardBehavior, isPinned: false))
        }
        memories = seeded
    }

    private func updateMemory(_ memory: MemoryRecord) {
        guard let index = memories.firstIndex(where: { $0.id == memory.id }) else { return }
        memories[index] = memory
    }

    private func deleteMemory(_ memory: MemoryRecord) {
        memories.removeAll { $0.id == memory.id }
    }

    private func exportLocalData() {
        let export = LocalExportBundle(
            profile: profile,
            memories: memories,
            messages: LocalPersistence.decode([ChatBubbleModel].self, from: storedChatMessages) ?? [],
            contactEvents: LocalPersistence.decode([ContactEvent].self, from: storedContactEvents) ?? [],
            completedJourneyDays: completedJourneyDays
        )
        UIPasteboard.general.string = LocalPersistence.encode(export)
    }

    private func clearAllLocalData() {
        profile = AppProfile()
        memories.removeAll()
        storedProfile = ""
        storedMemoryItems = ""
        storedChatMessages = ""
        storedContactEvents = ""
        completedJourneyDays = ""
        storedOnboardingCompleted = false
        dismiss()
    }
}

struct LocalExportBundle: Codable {
    var exportedAt = Date()
    let profile: AppProfile
    let memories: [MemoryRecord]
    let messages: [ChatBubbleModel]
    let contactEvents: [ContactEvent]
    let completedJourneyDays: String
}

struct MemoryRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var category: String
    var subject: String
    var content: String
    var importance = 0.75
    var confidence = 0.85
    var sourceMessageIDs: [String] = []
    var isPinned: Bool
    var createdAt = Date()
    var updatedAt = Date()
}

enum MemoryExtractor {
    static func extract(from message: ChatBubbleModel, profile: AppProfile) -> [MemoryRecord] {
        let text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }

        let lowercased = text.lowercased()
        var records: [MemoryRecord] = []

        if lowercased.contains("night") || lowercased.contains("midnight") || lowercased.contains("can't sleep") {
            records.append(
                MemoryRecord(
                    category: "trigger",
                    subject: "nights",
                    content: "\(profile.displayName) reports that nights make the breakup feel harder.",
                    importance: 0.86,
                    confidence: 0.82,
                    sourceMessageIDs: [message.id.uuidString],
                    isPinned: false
                )
            )
        }

        if lowercased.contains("story") || lowercased.contains("profile") || lowercased.contains("instagram") || lowercased.contains("social") {
            records.append(
                MemoryRecord(
                    category: "trigger",
                    subject: "social media",
                    content: "Social-media activity connected to \(profile.rememberedPerson) can trigger renewed urgency or interpretation.",
                    importance: 0.8,
                    confidence: 0.78,
                    sourceMessageIDs: [message.id.uuidString],
                    isPinned: false
                )
            )
        }

        if lowercased.contains("text") || lowercased.contains("call") || lowercased.contains("reach out") {
            records.append(
                MemoryRecord(
                    category: "feared behavior",
                    subject: "contact urge",
                    content: "\(profile.displayName) may feel pulled to contact \(profile.rememberedPerson) during hard moments.",
                    importance: 0.84,
                    confidence: 0.78,
                    sourceMessageIDs: [message.id.uuidString],
                    isPinned: false
                )
            )
        }

        if lowercased.contains("miss") || lowercased.contains("lonely") {
            records.append(
                MemoryRecord(
                    category: "recurring thought",
                    subject: "missing them",
                    content: "\(profile.displayName) described missing \(profile.rememberedPerson) or feeling lonely.",
                    importance: 0.72,
                    confidence: 0.74,
                    sourceMessageIDs: [message.id.uuidString],
                    isPinned: false
                )
            )
        }

        if message.sourceMode == "voice" {
            records.append(
                MemoryRecord(
                    category: "conversation source",
                    subject: "voice memory",
                    content: "A relevant fact was shared aloud and saved into the same history as text chat.",
                    importance: 0.62,
                    confidence: 0.9,
                    sourceMessageIDs: [message.id.uuidString],
                    isPinned: false
                )
            )
        }

        return records
    }
}

struct EditableMemoryRow: View {
    @Environment(\.palette) private var palette
    let memory: MemoryRecord
    let update: (MemoryRecord) -> Void
    let delete: (MemoryRecord) -> Void
    @State private var isEditing = false
    @State private var editedContent = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    var changed = memory
                    changed.isPinned.toggle()
                    changed.updatedAt = Date()
                    update(changed)
                } label: {
                    Image(systemName: memory.isPinned ? "pin.fill" : "pin")
                        .foregroundStyle(memory.isPinned ? palette.accent : palette.secondaryText)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    Text(memory.subject)
                        .foregroundStyle(palette.primaryText)
                    Text(memory.category)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                }
                Spacer()
                Button {
                    editedContent = memory.content
                    isEditing.toggle()
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(palette.secondaryText)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                Button(role: .destructive) {
                    delete(memory)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(palette.destructive)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }

            if isEditing {
                TextEditor(text: $editedContent)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .padding(10)
                    .frame(minHeight: 90)
                    .background(palette.background)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                PrimaryButton(title: "Save memory", systemImage: "checkmark") {
                    var changed = memory
                    changed.content = editedContent
                    changed.updatedAt = Date()
                    update(changed)
                    isEditing = false
                }
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    Text(memory.content)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                        .lineSpacing(4)
                    Text(sourceLabel)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var sourceLabel: String {
        if memory.sourceMessageIDs.isEmpty {
            return "Seeded from onboarding"
        }
        if memory.sourceMessageIDs.count == 1 {
            return "Linked to 1 saved message"
        }
        return "Linked to \(memory.sourceMessageIDs.count) saved messages"
    }
}

#Preview {
    ContentView()
}
