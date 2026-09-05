//
//  ContentView.swift
//  heal
//
//  Created on 9/4/26.
//

import SwiftUI
import UIKit
import AVFoundation
import CryptoKit

struct ContentView: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("storedProfile") private var storedProfile = ""
    @AppStorage("storedOnboardingCompleted") private var storedOnboardingCompleted = false
    @AppStorage(JourneyState.storageKey) private var storedJourneyState = ""
    @AppStorage("storedJourneyCheckIns") private var storedJourneyCheckIns = ""
    @AppStorage("storedMemoryItems") private var storedMemoryItems = ""
    @State private var profile = AppProfile()
    @State private var onboardingCompleted = false
    @State private var isBooting = true

    private var mode: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }

    var body: some View {
        ThemedRoot(appearanceMode: mode) {
            ZStack {
                if onboardingCompleted {
                    MainAppView(
                        profile: $profile,
                        appearanceMode: $appearanceMode,
                        onboardingCompleted: $onboardingCompleted
                    )
                } else {
                    OnboardingView(profile: $profile) {
                        storedJourneyState = JourneyState().encoded
                        storedMemoryItems = LocalPersistence.encode(
                            seededMemories(
                                existing: LocalPersistence.decode([MemoryRecord].self, from: storedMemoryItems) ?? [],
                                profile: profile
                            )
                        )
                        onboardingCompleted = true
                    }
                }

                if isBooting {
                    LaunchSplashView()
                        .transition(.opacity)
                }
            }
        }
        .task {
            await bootApp()
        }
        .onChange(of: profile) { _, newValue in
            storedProfile = LocalPersistence.encode(newValue)
        }
        .onChange(of: onboardingCompleted) { _, newValue in
            storedOnboardingCompleted = newValue
        }
    }

    private func bootApp() async {
        loadStoredState()
        _ = CompanionVoiceSamplePlayer.hasBundledSample
        try? await Task.sleep(for: .milliseconds(1200))
        withAnimation(.easeInOut(duration: 0.35)) {
            isBooting = false
        }
    }

    private func loadStoredState() {
        profile = LocalPersistence.decode(AppProfile.self, from: storedProfile) ?? AppProfile()
        onboardingCompleted = storedOnboardingCompleted
        if storedJourneyState.isEmpty {
            storedJourneyState = JourneyState().encoded
        }
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
    var trustedSupportName = ""
    var trustedSupportPhone = ""
    var companionName = ""

    enum CodingKeys: String, CodingKey {
        case userName
        case personName
        case relationshipType
        case duration
        case endingStatus
        case endedBy
        case contactStatus
        case contactGoals
        case lastContact
        case story
        case currentHurt
        case hardBehavior
        case trustedSupportName
        case trustedSupportPhone
        case companionName
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userName = try container.decodeIfPresent(String.self, forKey: .userName) ?? ""
        personName = try container.decodeIfPresent(String.self, forKey: .personName) ?? ""
        relationshipType = try container.decodeIfPresent(String.self, forKey: .relationshipType) ?? ""
        duration = try container.decodeIfPresent(String.self, forKey: .duration) ?? ""
        endingStatus = try container.decodeIfPresent(String.self, forKey: .endingStatus) ?? ""
        endedBy = try container.decodeIfPresent(String.self, forKey: .endedBy) ?? ""
        contactStatus = try container.decodeIfPresent(String.self, forKey: .contactStatus) ?? ""
        contactGoals = try container.decodeIfPresent(Set<String>.self, forKey: .contactGoals) ?? []
        lastContact = try container.decodeIfPresent(String.self, forKey: .lastContact) ?? ""
        story = try container.decodeIfPresent(String.self, forKey: .story) ?? ""
        currentHurt = try container.decodeIfPresent(String.self, forKey: .currentHurt) ?? ""
        hardBehavior = try container.decodeIfPresent(String.self, forKey: .hardBehavior) ?? ""
        trustedSupportName = try container.decodeIfPresent(String.self, forKey: .trustedSupportName) ?? ""
        trustedSupportPhone = try container.decodeIfPresent(String.self, forKey: .trustedSupportPhone) ?? ""
        companionName = try container.decodeIfPresent(String.self, forKey: .companionName) ?? ""
    }

    var displayName: String {
        userName.isEmpty ? "there" : userName
    }

    var rememberedPerson: String {
        personName.isEmpty ? "them" : personName
    }

    var companionDisplayName: String {
        companionName.isEmpty ? "Mara" : companionName
    }

    var trustedSupportDisplayName: String {
        trustedSupportName.isEmpty ? "someone safe" : trustedSupportName
    }

    var trustedSupportPhoneURL: URL? {
        let allowed = Set("0123456789+")
        let cleaned = String(trustedSupportPhone.filter { allowed.contains($0) })
        guard !cleaned.isEmpty else { return nil }
        return URL(string: "tel:\(cleaned)")
    }

    var trustedSupportMessageURL: URL? {
        let allowed = Set("0123456789+")
        let cleaned = String(trustedSupportPhone.filter { allowed.contains($0) })
        guard !cleaned.isEmpty else { return nil }
        return URL(string: "sms:\(cleaned)")
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

    var relationshipSummary: String {
        var pieces: [String] = []
        if !relationshipType.isEmpty {
            pieces.append(relationshipType.lowercased())
        }
        if !duration.isEmpty {
            pieces.append(duration.lowercased())
        }
        if pieces.isEmpty {
            return "what happened with \(rememberedPerson)"
        }
        return "\(pieces.joined(separator: ", ")) with \(rememberedPerson)"
    }

    var personalAcheLine: String {
        if !currentHurt.isEmpty {
            return "I remember the part that hurts most: \(currentHurt)"
        }
        if !story.isEmpty {
            return "I remember the shape of what happened. You do not have to start from zero."
        }
        return "We can stay with just the next honest sentence."
    }

    var boundaryLine: String {
        if contactGoals.isEmpty {
            return "We will slow the next decision down before you have to act."
        }
        return "I remember what you are trying to protect: \(contactGoals.sorted().joined(separator: ", "))."
    }

    var hardBehaviorLine: String {
        if hardBehavior.isEmpty {
            return "When the feeling spikes, we can pause before it turns into action."
        }
        return "When it gets bad, I remember you said you are most likely to \(hardBehavior.lowercased())."
    }

    var supportLine: String {
        if trustedSupportName.isEmpty {
            return "\(companionDisplayName) will stay here and talk through the next minute with you."
        }
        return "\(companionDisplayName) will stay here with you. \(trustedSupportName) is saved only if you choose to use that option."
    }

    var personalCallGreeting: String {
        let base = "Hi \(displayName). It is \(companionDisplayName)."
        if !currentHurt.isEmpty {
            return "\(base) I remember what you said hurts most: \(currentHurt). You do not have to make this sound neat. Tell me what is happening in your body right now."
        }
        if !personName.isEmpty {
            return "\(base) I remember \(rememberedPerson). Start anywhere, even if it comes out messy. What feels loudest right now?"
        }
        return "\(base) I am here with you. Take your time. Tell me the part that feels loudest right now."
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

struct SheetBackButton: View {
    @Environment(\.palette) private var palette
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: title == "Close" ? "xmark" : "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .foregroundStyle(palette.primaryText)
            .background(palette.card)
            .clipShape(Capsule())
            .overlay(
                Capsule()
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
                .frame(width: size * 0.86, height: size * 0.13)
                .offset(y: size * 0.42)

            if palette.isNight {
                Circle()
                    .fill(palette.accent.opacity(state == .hardMoment ? 0.24 : 0.14))
                    .frame(width: size * 1.45, height: size * 1.45)
                    .blur(radius: 24)
            }

            MaraOpenHandAvatar(state: state, size: size)
                .shadow(color: palette.accent.opacity(palette.isNight ? 0.28 : 0.14), radius: 18, x: 0, y: 9)

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
        .accessibilityHidden(true)
    }
}

struct MaraOpenHandAvatar: View {
    @Environment(\.palette) private var palette
    let state: CompanionState
    let size: CGFloat

    var body: some View {
        ZStack {
            palmGlow
            fingers
            palm
            thumb
            face
        }
        .frame(width: size * 1.22, height: size * 1.04)
    }

    private var palmGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hex: "FFE0B4").opacity(palette.isNight ? 0.28 : 0.36),
                        palette.accent.opacity(0.12),
                        .clear
                    ],
                    center: .center,
                    startRadius: 4,
                    endRadius: size * 0.58
                )
            )
            .frame(width: size * 1.02, height: size * 1.02)
            .offset(y: size * 0.02)
    }

    private var fingers: some View {
        HStack(spacing: size * 0.045) {
            finger(width: 0.17, height: 0.42, rotation: -14, y: -0.15)
            finger(width: 0.18, height: 0.52, rotation: -5, y: -0.2)
            finger(width: 0.18, height: 0.49, rotation: 5, y: -0.19)
            finger(width: 0.16, height: 0.38, rotation: 15, y: -0.13)
        }
        .offset(y: -size * 0.18)
    }

    private func finger(width: CGFloat, height: CGFloat, rotation: Double, y: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
            .fill(fleshGradient)
            .frame(width: size * width, height: size * height)
            .rotationEffect(.degrees(rotation))
            .offset(y: size * y)
    }

    private var palm: some View {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            .fill(fleshGradient)
            .frame(width: size * 0.88, height: size * 0.54)
            .clipShape(MaraPalmShape())
            .overlay(
                Circle()
                    .fill(Color(hex: "FFE0B4").opacity(palette.isNight ? 0.14 : 0.2))
                    .frame(width: size * 0.42, height: size * 0.42)
                    .blur(radius: 8)
                    .offset(y: -size * 0.07)
            )
            .offset(y: size * 0.16)
    }

    private var thumb: some View {
        RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
            .fill(Color(hex: "C27050"))
            .frame(width: size * 0.28, height: size * 0.15)
            .rotationEffect(.degrees(-28))
            .offset(x: -size * 0.46, y: size * 0.06)
    }

    private var face: some View {
        VStack(spacing: size * 0.055) {
            HStack(spacing: size * 0.16) {
                Eye(isConcerned: state == .concerned || state == .hardMoment)
                    .frame(width: size * 0.07, height: size * 0.1)
                Eye(isConcerned: state == .concerned || state == .hardMoment)
                    .frame(width: size * 0.07, height: size * 0.1)
            }
            Mouth(isSpeaking: state == .speaking, isConcerned: state == .concerned || state == .hardMoment)
                .frame(width: size * 0.12, height: size * 0.05)
        }
        .foregroundStyle(Color(hex: "2C211B").opacity(palette.isNight ? 0.72 : 0.82))
        .offset(y: size * 0.13)
    }

    private var fleshGradient: LinearGradient {
        LinearGradient(
            colors: [
                palette.isNight ? Color(hex: "D98C68") : Color(hex: "E6A078"),
                palette.isNight ? Color(hex: "BE6F51") : Color(hex: "C97557"),
                palette.isNight ? Color(hex: "99513E") : Color(hex: "A85742")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct MaraPalmShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.24))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.92, y: rect.minY + rect.height * 0.2), control1: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY), control2: CGPoint(x: rect.minX + rect.width * 0.72, y: rect.minY * 0.2))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.88, y: rect.minY + rect.height * 0.82), control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.42), control2: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.68))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.minY + rect.height * 0.78), control1: CGPoint(x: rect.minX + rect.width * 0.67, y: rect.maxY), control2: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.24), control1: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.62), control2: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.38))
        path.closeSubpath()
        return path
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
                    .frame(width: max(6, size * 0.13), height: max(6, size * 0.13))
            }
        }
        .padding(10)
        .background(palette.card.opacity(0.78))
        .clipShape(Capsule())
    }
}

struct BreathingPacer: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(palette.accent.opacity(0.24), lineWidth: 12)
                    .frame(width: 112, height: 112)
                Circle()
                    .fill(palette.accent.opacity(0.22))
                    .frame(width: 74, height: 74)
                    .scaleEffect(reduceMotion ? 1 : (isExpanded ? 1.42 : 0.82))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 4).repeatForever(autoreverses: true), value: isExpanded)
                Image(systemName: "lungs.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(palette.accent)
            }
            VStack(spacing: 4) {
                Text(isExpanded ? "Let it out" : "In gently")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.primaryText)
                Text("No fixing. Just breathe with me.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(palette.card.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.divider.opacity(0.8), lineWidth: 1)
        )
        .onAppear { isExpanded = true }
    }
}

struct LaunchSplashView: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                ZStack {
                    ForEach(0..<4) { index in
                        Circle()
                            .stroke(palette.accent.opacity(0.26 - Double(index) * 0.045), lineWidth: 7)
                            .frame(width: 92 + CGFloat(index * 34), height: 92 + CGFloat(index * 34))
                            .scaleEffect(reduceMotion ? 1 : (isExpanded ? 1.08 : 0.94))
                            .animation(
                                reduceMotion ? nil : .easeInOut(duration: 1.55 + Double(index) * 0.18).repeatForever(autoreverses: true),
                                value: isExpanded
                            )
                    }

                    CompanionCharacter(state: .resting, size: 112)
                }
                .frame(width: 220, height: 220)

                VStack(spacing: 8) {
                    Text("Heal Your Heart")
                        .font(.system(size: 38, weight: .semibold, design: .serif))
                        .foregroundStyle(palette.primaryText)
                    Text("Mara is getting close.")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                    Text(isExpanded ? "Let it out" : "In gently")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                        .frame(height: 24)
                        .padding(.top, 8)
                }
                .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear { isExpanded = true }
        .accessibilityLabel("Heal Your Heart is loading")
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
    @AppStorage("autoListenAfterMaraSpeaks") private var autoListenAfterMaraSpeaks = false
    @AppStorage("voiceGuidedSetupEnabled") private var voiceGuidedSetupEnabled = false
    @Binding var profile: AppProfile
    let complete: () -> Void
    @State private var step = 0
    @State private var setupSpeechService = AppleSpeechRecognitionService()
    @State private var setupTranscript = ""
    @State private var isSetupRecording = false
    @State private var setupSilenceTask: Task<Void, Never>?
    @State private var lastSpokenSetupStep = -1
    @State private var setupPromptTask: Task<Void, Never>?

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
                        if showsSetupVoiceAnswer {
                            setupVoiceAnswerPanel
                        }
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
        .onAppear {
            speakSetupPromptIfNeeded()
        }
        .onChange(of: step) { _, _ in
            setupPromptTask?.cancel()
            setupPromptTask = nil
            setupSilenceTask?.cancel()
            setupSilenceTask = nil
            setupTranscript = ""
            isSetupRecording = false
            setupSpeechService.cancelRecording()
            speakSetupPromptIfNeeded()
        }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(palette.divider.opacity(0.75))
                Capsule()
                    .fill(palette.accent)
                    .frame(width: proxy.size.width * CGFloat(step + 1) / 17)
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
        case 13:
            textStep(
                title: "Is there anyone safe you might want nearby?",
                placeholder: "Trusted person's name",
                text: $profile.trustedSupportName,
                subtitle: "This is optional. If no one comes to mind, leave it blank. You still belong here."
            )
        case 14:
            textStep(
                title: "Add their phone if you want a one-tap option.",
                placeholder: "Phone number",
                text: $profile.trustedSupportPhone,
                subtitle: "Only add this if it helps. You can skip it and add it later."
            )
        case 15:
            namingStep
        default:
            voiceStep
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
            WarmCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Let Mara walk me through it", systemImage: "waveform.circle.fill")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(palette.primaryText)
                    Text("She can ask each question out loud. You answer by talking, pause, and the app moves on.")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                        .lineSpacing(4)
                    Button {
                        voiceGuidedSetupEnabled = true
                        autoListenAfterMaraSpeaks = true
                        withAnimation(.easeInOut) {
                            step = 1
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "mic.fill")
                            Text("Talk through setup")
                        }
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .foregroundStyle(Color(hex: "2C211B"))
                        .background(palette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
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
            SectionTitle(title: "Set up who remembers.", subtitle: "Before you go home, give this voice a name. They will carry the tender parts you already shared.")
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
            WarmCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("They will remember first")
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(palette.primaryText)
                    DetailBulletList(items: initialMemoryPreview)
                }
            }
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

    private var voiceStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            CompanionCharacter(state: .listening, size: 150)
                .frame(maxWidth: .infinity)
            SectionTitle(
                title: "Choose the voice that stays with you.",
                subtitle: "This app uses one companion voice. You can hear it before you open Home."
            )
            VoiceSettingsCard()
            AutoListenConsentCard(isEnabled: $autoListenAfterMaraSpeaks)
        }
    }

    private var initialMemoryPreview: [String] {
        var items = [
            "Your name is \(profile.displayName).",
            "This is about \(profile.relationshipSummary)."
        ]

        if !profile.currentHurt.isEmpty {
            items.append(profile.personalAcheLine)
        }
        if !profile.contactGoals.isEmpty {
            items.append(profile.boundaryLine)
        }
        if !profile.hardBehavior.isEmpty {
            items.append(profile.hardBehaviorLine)
        }
        if !profile.trustedSupportName.isEmpty {
            items.append(profile.supportLine)
        } else {
            items.append("If no one personal is available, crisis support is still there.")
        }

        return items
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button {
                    withAnimation(.easeInOut) { step -= 1 }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                        Text("Back")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .frame(width: 104, height: 52)
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

            PrimaryButton(title: step == 0 ? "Start healing" : step == 16 ? "Open Home" : "Continue", systemImage: step == 0 ? "heart.fill" : "arrow.right") {
                withAnimation(.easeInOut) {
                    if step >= 16 {
                        if profile.companionName.isEmpty {
                            profile.companionName = "Mara"
                        }
                        complete()
                    } else {
                        if step == 0 {
                            voiceGuidedSetupEnabled = false
                        }
                        step += 1
                    }
                }
            }
            .disabled(!canContinue)
            .opacity(canContinue ? 1 : 0.45)
        }
    }

    private var canContinue: Bool {
        step != 16 || CompanionVoiceSamplePlayer.hasBundledSample
    }

    private var showsSetupVoiceAnswer: Bool {
        (1...15).contains(step)
    }

    private var setupVoiceAnswerPanel: some View {
        WarmCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: isSetupRecording ? "waveform.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(palette.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(isSetupRecording ? "Mara is listening" : "Answer out loud")
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                            .foregroundStyle(palette.primaryText)
                        Text(isSetupRecording ? "Pause when you are done. I will catch it." : "You can say the answer instead of typing.")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                    }
                    Spacer(minLength: 0)
                }

                if !setupTranscript.isEmpty {
                    Text(setupTranscript)
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                        .lineSpacing(4)
                }

                HStack(spacing: 10) {
                    Button {
                        Task {
                            if isSetupRecording {
                                await stopAndApplySetupAnswer(advance: true)
                            } else {
                                await startSetupRecording()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isSetupRecording ? "stop.fill" : "mic.fill")
                            Text(isSetupRecording ? "Done" : "Talk to answer")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundStyle(Color(hex: "2C211B"))
                        .background(isSetupRecording ? palette.blush : palette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        speakSetupPromptIfNeeded(force: true)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 52, height: 50)
                            .foregroundStyle(palette.primaryText)
                            .background(palette.background)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .accessibilityLabel("Hear question again")
                }
            }
        }
    }

    private func speakSetupPromptIfNeeded(force: Bool = false) {
        guard voiceGuidedSetupEnabled, showsSetupVoiceAnswer, force || lastSpokenSetupStep != step else { return }
        lastSpokenSetupStep = step
        let prompt = setupPromptForCurrentStep
        setupPromptTask = Task {
            await SpeechPlaybackEngine.shared.prepareLiveVoice()
            _ = await SpeechPlaybackEngine.shared.speakLive(prompt)
        }
    }

    private var setupPromptForCurrentStep: String {
        switch step {
        case 1: "What should I call you?"
        case 2: "Who are we getting over?"
        case 3: "What were they to you?"
        case 4: "How long were they part of your life?"
        case 5: "When did things end?"
        case 6: "Who ended it?"
        case 7: "Are you still talking?"
        case 8: "What are you trying to do right now? Say anything that fits."
        case 9: "When did you last have contact?"
        case 10: "Tell me what happened."
        case 11: "What hurts the most right now?"
        case 12: "When it gets bad, what are you most likely to do?"
        case 13: "Is there anyone safe you might want nearby? You can say skip."
        case 14: "Add their phone if you want. You can say skip."
        case 15: "What should we call the voice who stays with you?"
        default: ""
        }
    }

    private func startSetupRecording() async {
        do {
            setupTranscript = ""
            SpeechPlaybackEngine.shared.stop()
            let contextualStrings = [
                profile.displayName,
                profile.rememberedPerson,
                profile.companionDisplayName
            ].filter { !$0.isEmpty && $0 != "there" && $0 != "them" }
            try await setupSpeechService.startRecording(contextualStrings: contextualStrings) { partial in
                setupTranscript = partial
                scheduleSetupSilenceAutoApply()
            }
            isSetupRecording = true
        } catch {
            isSetupRecording = false
            setupTranscript = error.localizedDescription
        }
    }

    private func stopAndApplySetupAnswer(advance: Bool) async {
        setupSilenceTask?.cancel()
        setupSilenceTask = nil
        do {
            setupTranscript = try await setupSpeechService.stopRecording()
            isSetupRecording = false
            applySetupAnswer(setupTranscript)
            if advance, canContinue, step < 16 {
                withAnimation(.easeInOut) {
                    step += 1
                }
            }
        } catch {
            isSetupRecording = false
            setupTranscript = error.localizedDescription
        }
    }

    private func scheduleSetupSilenceAutoApply() {
        setupSilenceTask?.cancel()
        let trimmed = setupTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        setupSilenceTask = Task {
            try? await Task.sleep(for: .milliseconds(1300))
            guard !Task.isCancelled else { return }
            await stopAndApplySetupAnswer(advance: true)
        }
    }

    private func applySetupAnswer(_ rawAnswer: String) {
        let answer = rawAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else { return }
        if ["skip", "none", "no one", "nobody"].contains(answer.lowercased()), step == 13 || step == 14 {
            if step == 13 { profile.trustedSupportName = "" }
            if step == 14 { profile.trustedSupportPhone = "" }
            return
        }

        switch step {
        case 1:
            profile.userName = answer
        case 2:
            profile.personName = answer
        case 3:
            profile.relationshipType = bestMatchingOption(from: relationshipTypes, answer: answer) ?? answer
        case 4:
            profile.duration = bestMatchingOption(from: durations, answer: answer) ?? answer
        case 5:
            let options = ["It hasn't completely ended", "I'm not sure", "Skip"]
            profile.endingStatus = bestMatchingOption(from: options, answer: answer) ?? answer
        case 6:
            profile.endedBy = bestMatchingOption(from: endedByOptions, answer: answer) ?? answer
        case 7:
            profile.contactStatus = bestMatchingOption(from: communicationOptions, answer: answer) ?? answer
        case 8:
            let matches = contactGoals.filter { answerMatches($0, answer: answer) }
            if matches.isEmpty {
                profile.contactGoals.insert(answer)
            } else {
                for match in matches {
                    profile.contactGoals.insert(match)
                }
            }
        case 9:
            profile.lastContact = bestMatchingOption(from: lastContactOptions, answer: answer) ?? answer
        case 10:
            profile.story = appendSpoken(answer, to: profile.story)
        case 11:
            profile.currentHurt = appendSpoken(answer, to: profile.currentHurt)
        case 12:
            profile.hardBehavior = bestMatchingOption(from: hardBehaviorOptions, answer: answer) ?? answer
        case 13:
            profile.trustedSupportName = answer
        case 14:
            profile.trustedSupportPhone = answer
        case 15:
            profile.companionName = answer
        default:
            break
        }
    }

    private func bestMatchingOption(from options: [String], answer: String) -> String? {
        options.first { answerMatches($0, answer: answer) }
    }

    private func answerMatches(_ option: String, answer: String) -> Bool {
        let answerWords = Set(normalizedWords(answer))
        let optionWords = normalizedWords(option).filter { !["a", "an", "the", "to", "it", "is", "was", "were", "we", "my", "i"].contains($0) }
        return optionWords.contains { answerWords.contains($0) }
    }

    private func normalizedWords(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private func appendSpoken(_ answer: String, to existing: String) -> String {
        let trimmed = existing.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? answer : "\(trimmed)\n\n\(answer)"
    }
}

// MARK: - Main App

struct MainAppView: View {
    @Binding var profile: AppProfile
    @Binding var appearanceMode: String
    @Binding var onboardingCompleted: Bool

    var body: some View {
        TabView {
            HomeView(
                profile: $profile,
                appearanceMode: $appearanceMode,
                onboardingCompleted: $onboardingCompleted
            )
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
    @AppStorage(JourneyState.storageKey) private var storedJourneyState = ""
    @AppStorage("storedFeelingCheckIns") private var storedFeelingCheckIns = ""
    @Binding var profile: AppProfile
    @Binding var appearanceMode: String
    @Binding var onboardingCompleted: Bool
    @State private var showingHardMoment = false
    @State private var showingSettings = false
    @State private var showingBuddyCall = false
    @State private var callOpeningPrompt: String?
    @State private var openDay: JourneyDay?

    private var journey: JourneyState {
        JourneyState.load(from: storedJourneyState)
    }

    var body: some View {
        NavigationStack {
            WarmScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        topSection
                        needYouButton
                        callBuddyButton
                        feelingCheckIn
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
                SettingsView(
                    profile: $profile,
                    appearanceMode: $appearanceMode,
                    onboardingCompleted: $onboardingCompleted
                )
            }
            .fullScreenCover(isPresented: $showingBuddyCall) {
                BuddyCallView(profile: profile, openingPrompt: callOpeningPrompt)
            }
            .sheet(item: $openDay) { day in
                JourneyDayDetail(day: day, profile: profile) {
                    markJourneyDayCompleted(day.number)
                }
            }
        }
    }

    private var topSection: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(greeting), \(profile.displayName).")
                    .font(.system(size: 36, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.primaryText)
                    .lineSpacing(3)
                Text(profile.personalAcheLine)
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

    private var callBuddyButton: some View {
        Button {
            callOpeningPrompt = nil
            showingBuddyCall = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 23, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .foregroundStyle(Color(hex: "2C211B"))
                    .background(palette.blush.opacity(0.78))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("Call \(profile.companionDisplayName)")
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(palette.primaryText)
                    Text("Say the messy part out loud and hear them answer back.")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(palette.secondaryText)
            }
            .padding(18)
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var feelingCheckIn: some View {
        WarmCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How is your heart right now?")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundStyle(palette.primaryText)
                    Text(latestFeelingLine)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                        .lineSpacing(4)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                    ForEach(FeelingCheckInOption.allCases) { option in
                        Button {
                            saveFeeling(option)
                        } label: {
                            VStack(spacing: 7) {
                                Image(systemName: option.systemImage)
                                    .font(.system(size: 20, weight: .semibold))
                                Text(option.title)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .foregroundStyle(selectedFeeling == option ? Color(hex: "2C211B") : palette.primaryText)
                            .background(selectedFeeling == option ? palette.accent : palette.background)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(selectedFeeling == option ? palette.accent : palette.divider, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let selectedFeeling {
                    SecondaryButton(title: "Talk through \(selectedFeeling.title.lowercased())", systemImage: "mic.fill") {
                        callOpeningPrompt = "\(profile.companionDisplayName) here, \(profile.displayName). I saw you chose \(selectedFeeling.title.lowercased()). I am staying with you inside this. \(selectedFeeling.openingLine(for: profile))"
                        showingBuddyCall = true
                    }
                }
            }
        }
    }

    private var feelingCheckIns: [FeelingCheckIn] {
        LocalPersistence.decode([FeelingCheckIn].self, from: storedFeelingCheckIns) ?? []
    }

    private var selectedFeeling: FeelingCheckInOption? {
        feelingCheckIns.sorted { $0.createdAt > $1.createdAt }.first.flatMap { FeelingCheckInOption(rawValue: $0.optionRawValue) }
    }

    private var latestFeelingLine: String {
        guard let latest = feelingCheckIns.sorted(by: { $0.createdAt > $1.createdAt }).first,
              let option = FeelingCheckInOption(rawValue: latest.optionRawValue) else {
            return "Tap the closest one. It is enough to begin there."
        }
        return "Last check-in: \(option.title.lowercased()) at \(latest.createdAt.formatted(date: .omitted, time: .shortened))."
    }

    private func saveFeeling(_ option: FeelingCheckInOption) {
        var updated = feelingCheckIns
        updated.append(FeelingCheckIn(option: option))
        storedFeelingCheckIns = LocalPersistence.encode(updated.suffix(30).map { $0 })
        callOpeningPrompt = "\(profile.companionDisplayName) here, \(profile.displayName). I saw you chose \(option.title.lowercased()). \(option.openingLine(for: profile))"
    }

    @ViewBuilder
    private var todaysJourney: some View {
        let current = journey
        if let day = current.currentDay {
            WarmCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("DAY \(day.number)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                    Text(day.title)
                        .font(.system(size: 25, weight: .semibold, design: .serif))
                        .foregroundStyle(palette.primaryText)
                        Text(day.lesson)
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                            .lineSpacing(5)
                        Text(profile.boundaryLine)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                            .lineSpacing(4)
                        PrimaryButton(
                            title: current.isCompleted(day.number) ? "Revisit" : "Continue",
                            systemImage: "arrow.right"
                    ) {
                        openDay = JourneyDay(content: day, state: current.displayState(for: day.number))
                    }
                }
            }
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<5: "Still awake"
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        default: "Good evening"
        }
    }

    private func markJourneyDayCompleted(_ number: Int) {
        var updated = journey
        updated.markCompleted(number)
        storedJourneyState = updated.encoded
        openDay = openDay?.replacingState(.completed)
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
        let current = journey
        return VStack(alignment: .leading, spacing: 12) {
            Text("CURRENT PHASE")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(palette.secondaryText)
            Text(current.currentPhase.rawValue)
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(palette.primaryText)
            ProgressView(value: current.progressFraction)
                .tint(palette.accent)
            Text("\(current.progressPercent)% of your current Journey")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(palette.secondaryText)
        }
        .padding(.vertical, 8)
    }
}

struct JourneyView: View {
    @Environment(\.palette) private var palette
    @AppStorage(JourneyState.storageKey) private var storedJourneyState = ""
    @AppStorage("storedJourneyCheckIns") private var storedJourneyCheckIns = ""
    let profile: AppProfile
    @State private var selectedDay: JourneyDay?

    private var journey: JourneyState {
        JourneyState.load(from: storedJourneyState)
    }

    private var selectedLength: Binding<Int> {
        Binding(
            get: { journey.selectedLength },
            set: { newValue in
                var updated = journey
                updated.select(length: newValue)
                storedJourneyState = updated.encoded
            }
        )
    }

    var body: some View {
        NavigationStack {
            WarmScreen {
                ScrollView {
                    let current = journey
                    VStack(alignment: .leading, spacing: 28) {
                        SectionTitle(title: "Your Journey", subtitle: "A warm path through the first difficult stretch. No journal. No homework wall.")

                        Picker("Journey length", selection: selectedLength) {
                            ForEach(JourneyLibrary.availableLengths, id: \.self) { length in
                                Text("\(length)").tag(length)
                            }
                        }
                        .pickerStyle(.segmented)

                        WarmCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("\(current.progressPercent)%")
                                    .font(.system(size: 58, weight: .semibold, design: .serif))
                                    .foregroundStyle(palette.primaryText)
                                Text("of your current Journey")
                                    .font(.system(size: 17, weight: .regular, design: .rounded))
                                    .foregroundStyle(palette.secondaryText)
                                ProgressView(value: current.progressFraction)
                                    .tint(palette.accent)
                                Text("\(current.completedCountInJourney) of \(current.selectedLength) days complete")
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundStyle(palette.secondaryText)
                            }
                        }

                        ForEach(JourneyPhase.allCases) { phase in
                            let phaseDays = days(in: phase, of: current)
                            if !phaseDays.isEmpty {
                                phaseSection(phase: phase, days: phaseDays)
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

    private func phaseSection(phase: JourneyPhase, days: [JourneyDay]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(phase.rawValue.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(palette.secondaryText)

            VStack(spacing: 0) {
                ForEach(days) { day in
                    Button {
                        selectedDay = day
                    } label: {
                        JourneyRow(day: day, hasCheckIn: hasCheckIn(for: day.number))
                    }
                    .buttonStyle(.plain)
                    .disabled(day.state == .locked)
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
    }

    private func days(in phase: JourneyPhase, of current: JourneyState) -> [JourneyDay] {
        current.days
            .filter { phase.dayRange.contains($0.number) }
            .map { JourneyDay(content: $0, state: current.displayState(for: $0.number)) }
    }

    private func markCompleted(_ number: Int) {
        var updated = journey
        updated.markCompleted(number)
        storedJourneyState = updated.encoded
        selectedDay = selectedDay?.replacingState(.completed)
    }

    private func hasCheckIn(for number: Int) -> Bool {
        let checkIns = LocalPersistence.decode([Int: String].self, from: storedJourneyCheckIns) ?? [:]
        return !(checkIns[number] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct JourneyDay: Identifiable, Equatable {
    enum State {
        case completed
        case current
        case upcoming
        case locked
    }

    var id: Int { number }
    let number: Int
    let title: String
    let phase: String
    let state: State
    let lesson: String
    let action: String
    let checkIn: String

    init(number: Int, title: String, phase: String, state: State, lesson: String, action: String, checkIn: String) {
        self.number = number
        self.title = title
        self.phase = phase
        self.state = state
        self.lesson = lesson
        self.action = action
        self.checkIn = checkIn
    }

    init(content: JourneyContentDay, state: State) {
        self.init(
            number: content.number,
            title: content.title,
            phase: content.phase,
            state: state,
            lesson: content.lesson,
            action: content.action,
            checkIn: content.checkIn
        )
    }

    func replacingState(_ newState: State) -> JourneyDay {
        JourneyDay(number: number, title: title, phase: phase, state: newState, lesson: lesson, action: action, checkIn: checkIn)
    }
}

enum JourneyDetailSection: String, CaseIterable, Identifiable {
    case lesson
    case action
    case talk
    case steady

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lesson: "Read"
        case .action: "Do"
        case .talk: "Talk"
        case .steady: "Steady"
        }
    }

    var heading: String {
        switch self {
        case .lesson: "One thought"
        case .action: "One small thing"
        case .talk: "Two ways in"
        case .steady: "If it spikes"
        }
    }
}

extension JourneyState {
    func displayState(for number: Int) -> JourneyDay.State {
        if isCompleted(number) { return .completed }
        if number == currentDayNumber { return .current }
        if isLocked(number) { return .locked }
        return .upcoming
    }
}

struct JourneyRow: View {
    @Environment(\.palette) private var palette
    let day: JourneyDay
    var hasCheckIn = false

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
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                if hasCheckIn {
                    Label("Small note saved", systemImage: "text.bubble.fill")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.accent)
                }
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
        case .current: day.lesson
        case .upcoming: "Coming up"
        case .locked: "Unlocks as your path continues"
        }
    }
}

struct JourneyDayDetail: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @AppStorage("storedJourneyCheckIns") private var storedJourneyCheckIns = ""
    let day: JourneyDay
    let profile: AppProfile
    let markCompleted: () -> Void
    @State private var showingTalkToMe = false
    @State private var checkInText = ""
    @State private var selectedDetailSection: JourneyDetailSection = .lesson

    var body: some View {
        NavigationStack {
            WarmScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        SheetBackButton(title: "Back") {
                            dismiss()
                        }

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

                        PrimaryButton(title: "Talk to me", systemImage: "mic.fill") {
                            showingTalkToMe = true
                        }

                        Picker("Day section", selection: $selectedDetailSection) {
                            ForEach(JourneyDetailSection.allCases) { section in
                                Text(section.title).tag(section)
                            }
                        }
                        .pickerStyle(.segmented)

                        focusedDetailCard

                        WarmCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Leave a small note")
                                    .font(.system(size: 21, weight: .semibold, design: .serif))
                                    .foregroundStyle(palette.primaryText)
                                TextEditor(text: $checkInText)
                                    .scrollContentBackground(.hidden)
                                    .font(.system(size: 17, weight: .regular, design: .rounded))
                                    .foregroundStyle(palette.primaryText)
                                    .padding(12)
                                    .frame(minHeight: 120)
                                    .background(palette.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(palette.divider, lineWidth: 1)
                                    )
                                Text(checkInText.isEmpty ? "This can be one sentence. It stays here with this day." : "Saved with Day \(day.number).")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundStyle(palette.secondaryText)
                            }
                        }

                        PrimaryButton(title: day.state == .completed ? "Completed" : "Mark complete", systemImage: "checkmark.circle.fill") {
                            saveCheckIn()
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
            .fullScreenCover(isPresented: $showingTalkToMe) {
                BuddyCallView(
                    profile: profile,
                    contextTitle: "Day \(day.number): \(day.title)",
                    openingPrompt: "\(profile.companionDisplayName) here, \(profile.displayName). I am right here. This is Day \(day.number): \(day.title), and I remember this is tied to \(profile.relationshipSummary). \(profile.personalAcheLine) Say the messy version out loud. I will stay with you while you get it out."
                )
            }
            .onAppear(perform: loadCheckIn)
            .onChange(of: checkInText) { _, _ in
                saveCheckIn()
            }
        }
    }

    private func loadCheckIn() {
        let checkIns = LocalPersistence.decode([Int: String].self, from: storedJourneyCheckIns) ?? [:]
        checkInText = checkIns[day.number] ?? ""
    }

    private func saveCheckIn() {
        var checkIns = LocalPersistence.decode([Int: String].self, from: storedJourneyCheckIns) ?? [:]
        let trimmed = checkInText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            checkIns.removeValue(forKey: day.number)
        } else {
            checkIns[day.number] = checkInText
        }
        storedJourneyCheckIns = LocalPersistence.encode(checkIns)
    }

    private var focusedDetailCard: some View {
        WarmCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(selectedDetailSection.heading)
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.primaryText)
                switch selectedDetailSection {
                case .lesson:
                    Text(day.lesson)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                        .lineSpacing(5)
                case .action:
                    Text(day.action)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                        .lineSpacing(5)
                case .talk:
                    DetailBulletList(items: Array(talkPrompts.prefix(2)))
                case .steady:
                    DetailBulletList(items: Array(hardMomentPlan.prefix(2)))
                }
            }
        }
    }

    private var talkPrompts: [String] {
        [
            "What part of this lesson feels tender or hard to believe right now?",
            "Where does \(profile.rememberedPerson) fit into this today: fact, hope, fear, habit, grief, or the \(profile.relationshipType.isEmpty ? "relationship" : profile.relationshipType.lowercased()) you wanted back?",
            "What would \(profile.companionDisplayName) say gently if they were only trying to protect the next ten minutes?"
        ]
    }

    private var hardMomentPlan: [String] {
        switch JourneyPhase.phase(forDay: day.number) {
        case .stabilize:
            return [
                "Start with your body before your story: water, food, breath, or lying down.",
                "Do not solve the whole relationship while your nervous system is alarmed.",
                "If you feel unsafe alone, stay in the call and use the immediate-danger button only if someone may be hurt right now."
            ]
        case .cutOffAndUnderstand:
            return [
                "Wait ten minutes before texting, calling, checking, or rereading.",
                "Name the exact outcome you want from contact with \(profile.rememberedPerson).",
                "Compare that hoped-for outcome with what usually happens afterward."
            ]
        case .untangleTheStory:
            return [
                "Hold one warm memory beside one painful pattern without editing either one out.",
                "Ask whether you are missing \(profile.rememberedPerson), the routine, or the future you imagined.",
                "Treat unanswered questions as pain, not instructions."
            ]
        case .rebuildSelfTrust:
            return [
                "Choose one promise to yourself that is small enough to keep today.",
                "Notice where you are waiting for \(profile.rememberedPerson) to validate a decision that belongs to you.",
                "If you slip, record what happened and keep the Journey progress intact."
            ]
        case .moveForward:
            return [
                "Look for the part of your day that is no longer organized around their reaction.",
                "Choose connection with someone available instead of chasing certainty from someone unavailable.",
                "Let a good moment be real without using it to test whether you are fully healed."
            ]
        }
    }

}

struct DetailBulletList: View {
    @Environment(\.palette) private var palette
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(palette.accent)
                        .padding(.top, 2)
                    Text(item)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
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
    @AppStorage(JourneyState.storageKey) private var storedJourneyState = ""
    let profile: AppProfile
    @State private var mode: TalkMode = .chat
    @State private var draft = ""
    @State private var isThinking = false
    @State private var voiceTask: Task<Void, Never>?
    private let engine = CompanionEngine()
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

                    chatQuickPrompts
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)

                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(messages) { message in
                                    ChatBubble(
                                        message: message,
                                        companionName: profile.companionDisplayName,
                                        isRemembered: isRemembered(message),
                                        sendSuggestedReply: sendQuickMessage,
                                        togglePinned: {
                                            togglePinned(message)
                                        },
                                        rememberMessage: {
                                            rememberMessage(message)
                                        },
                                        forgetMessage: {
                                            forgetMessage(message)
                                        },
                                        deleteMessage: {
                                            deleteMessage(message)
                                        }
                                    )
                                        .id(message.id)
                                }
                                if isThinking {
                                    HStack {
                                        ThinkingDots(size: 60)
                                        Spacer()
                                    }
                                    .id("thinking")
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
        .onDisappear {
            voiceTask?.cancel()
            voiceTask = nil
            SpeechPlaybackEngine.shared.stop()
        }
        .onChange(of: messages) { _, newValue in
            storedChatMessages = LocalPersistence.encode(newValue)
        }
        .onChange(of: memories) { _, newValue in
            storedMemoryItems = LocalPersistence.encode(newValue)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
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

    private var chatQuickPrompts: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("If starting is hard")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(palette.secondaryText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chatPromptButton("Stay with me", systemImage: "heart.fill")
                    chatPromptButton("I feel alone", systemImage: "person.fill.questionmark")
                    chatPromptButton("I miss them", systemImage: "heart.text.square.fill")
                    chatPromptButton("I want to reach out", systemImage: "hand.raised.fill")
                    chatPromptButton("I am spiraling", systemImage: "waveform.path.ecg")
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func chatPromptButton(_ title: String, systemImage: String) -> some View {
        Button {
            sendQuickMessage(title)
        } label: {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 13)
            .frame(height: 38)
            .foregroundStyle(palette.primaryText)
            .background(palette.card)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(palette.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isThinking)
    }

    private func sendMessage() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }
        send(trimmed, sourceMode: mode == .talk ? "voice" : "text")
        draft = ""
    }

    private func sendQuickMessage(_ text: String) {
        send(text, sourceMode: "quick_prompt")
    }

    private func send(_ text: String, sourceMode: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }
        let userMessage = ChatBubbleModel(role: .user, text: trimmed, sourceMode: sourceMode)
        messages.append(userMessage)
        rememberFacts(from: userMessage)

        isThinking = true

        Task {
            let response = await engine.reply(
                to: trimmed,
                context: CompanionContext(profile: profile, recentMessages: messages, memories: memories),
                journeyPhase: JourneyState.load(from: storedJourneyState).currentPhase.rawValue
            )
            isThinking = false
            messages.append(
                ChatBubbleModel(
                    role: .companion,
                    text: response.reply,
                    sourceMode: "voice",
                    suggestedReplies: suggestedReplies(for: response)
                )
            )
            speakCompanionText(response.reply)
        }
    }

    private func speakCompanionText(_ text: String) {
        voiceTask?.cancel()
        SpeechPlaybackEngine.shared.stop()
        voiceTask = Task {
            await SpeechPlaybackEngine.shared.prepareLiveVoice()
            guard !Task.isCancelled else { return }
            _ = await SpeechPlaybackEngine.shared.speakLive(text)
        }
    }

    private func loadMessages() {
        guard let decoded = LocalPersistence.decode([ChatBubbleModel].self, from: storedChatMessages), !decoded.isEmpty else {
            messages = [
                ChatBubbleModel(
                    role: .companion,
                    text: "Hi. I am \(profile.companionDisplayName). You do not have to explain everything again. I'll remember what matters here.",
                    suggestedReplies: [
                        "Stay with me",
                        "I feel alone",
                        "I miss \(profile.rememberedPerson)"
                    ]
                )
            ]
            return
        }
        messages = decoded.filter { !$0.isDeleted }
    }

    private func suggestedReplies(for response: CompanionReply) -> [String] {
        if response.suggestedAction == "safety" {
            return ["Stay with me", "Breathe with me", "I am still here"]
        }
        if response.suggestedAction == "breathing" {
            return ["I can see one thing", "Keep breathing with me", "I feel a little calmer"]
        }
        if response.suggestedAction == "delay_timer" {
            return ["Help me not text", "What do I actually want?", "Stay with me"]
        }
        if response.suggestedAction == "facts_hopes_fears" {
            return ["This is a fact", "This is what I fear", "I need help sorting it"]
        }
        if response.suggestedAction == "slip_review" {
            return ["I want to tell you what happened", "I feel ashamed", "Help me keep going"]
        }
        return [
            "Tell me more",
            "Ask me gently",
            "Stay with me"
        ]
    }

    private func loadMemories() {
        memories = seededMemories(existing: LocalPersistence.decode([MemoryRecord].self, from: storedMemoryItems) ?? [], profile: profile)
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

    private func isRemembered(_ message: ChatBubbleModel) -> Bool {
        memories.contains { $0.sourceMessageIDs.contains(message.id.uuidString) }
    }

    private func rememberMessage(_ message: ChatBubbleModel) {
        let sourceID = message.id.uuidString
        guard !isRemembered(message) else { return }

        memories.append(
            MemoryRecord(
                category: "saved message",
                subject: message.role == .user ? "What \(profile.displayName) said" : "What \(profile.companionDisplayName) said",
                content: message.text,
                importance: message.role == .user ? 0.82 : 0.68,
                confidence: 1.0,
                sourceMessageIDs: [sourceID],
                isPinned: false
            )
        )
    }

    private func forgetMessage(_ message: ChatBubbleModel) {
        let sourceID = message.id.uuidString
        memories = memories.compactMap { memory in
            guard memory.sourceMessageIDs.contains(sourceID) else { return memory }

            var changed = memory
            changed.sourceMessageIDs.removeAll { $0 == sourceID }
            changed.updatedAt = Date()

            if changed.sourceMessageIDs.isEmpty {
                return nil
            }
            return changed
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
    var suggestedReplies: [String] = []
    var isPinned = false
    var isDeleted = false
}

struct CompanionContext {
    let profile: AppProfile
    let recentMessages: [ChatBubbleModel]
    let memories: [MemoryRecord]
}

struct CompanionReply {
    let reply: String
    let suggestedAction: String?
}

protocol CompanionService {
    func send(message: String, context: CompanionContext) -> CompanionReply
}

@MainActor
final class CompanionVoiceSamplePlayer {
    static let shared = CompanionVoiceSamplePlayer()
    static let clonedVoiceName = "Mara's voice"
    static var hasBundledSample: Bool {
        Bundle.main.url(forResource: "sample_cloned_voice", withExtension: "m4a") != nil ||
        bundledLineURL(forAssetName: sampleLineAssetName) != nil
    }

    private static let sampleLineAssetName = "companion-cloned-voice-sample"

    func play() {
        if Bundle.main.url(forResource: "sample_cloned_voice", withExtension: "m4a") != nil {
            MaraVoice.shared.play(clip: "sample_cloned_voice")
        } else {
            _ = playBundledLine(assetName: Self.sampleLineAssetName)
        }
    }

    @discardableResult
    func playLine(for text: String) -> Bool {
        let assetName = Self.lineAssetName(for: text)
        return playBundledLine(assetName: assetName)
    }

    func speakLive(_ text: String) async throws {
        MaraVoice.shared.stop()
        try await MaraVoice.shared.speak(text)
    }

    func prepareLiveVoice() async {
        await MaraVoice.shared.prepare()
    }

    func stop() {
        MaraVoice.shared.stop()
    }

    private func playBundledLine(assetName: String) -> Bool {
        guard let url = Self.bundledLineURL(forAssetName: assetName) else {
            return false
        }

        let clipName = url.deletingPathExtension().lastPathComponent
        MaraVoice.shared.play(clip: clipName, ext: url.pathExtension)
        return true
    }

    static func lineAssetName(for text: String) -> String {
        let cleaned = normalized(text)
        let digest = SHA256.hash(data: Data(cleaned.utf8))
        let hash = digest.map { String(format: "%02x", $0) }.joined()
        return "mara-line-\(hash)"
    }

    private static func bundledLineURL(forAssetName assetName: String) -> URL? {
        Bundle.main.url(forResource: assetName, withExtension: "wav") ??
        Bundle.main.url(forResource: assetName, withExtension: "m4a")
    }

    private static func normalized(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .split(separator: " ")
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

final class SpeechPlaybackEngine: NSObject {
    static let shared = SpeechPlaybackEngine()

    private override init() {
        super.init()
    }

    func speakLive(_ text: String) async -> Bool {
        stop()
        if CompanionVoiceSamplePlayer.shared.playLine(for: text) {
            return true
        }

        do {
            try await CompanionVoiceSamplePlayer.shared.speakLive(text)
            return true
        } catch {
            return false
        }
    }

    func prepareLiveVoice() async {
        await CompanionVoiceSamplePlayer.shared.prepareLiveVoice()
    }

    func stop() {
        CompanionVoiceSamplePlayer.shared.stop()
    }

}

struct LocalCompanionService: CompanionService {
    func send(message: String, context: CompanionContext) -> CompanionReply {
        let lowercased = message.lowercased()
        let profile = context.profile
        let personName = profile.rememberedPerson
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
                reply: "\(profile.displayName), I remember this is about \(personName), and I am taking this seriously. Stay with me here. Put distance between you and anything you could use to hurt yourself. We are only handling the next minute together. If someone may be hurt right now, use the immediate danger button too.",
                suggestedAction: "safety"
            )
        }

        if containsAny(lowercased, words: ["stay with me", "don't leave", "dont leave", "please stay", "breathe with me"]) {
            return CompanionReply(
                reply: "I am here, \(profile.displayName). You do not have to perform being okay for me. Put one hand on your chest if that helps. We are only doing the next minute: breathe out slowly, look around the room, and tell me one thing you can see.",
                suggestedAction: "breathing"
            )
        }

        if containsAny(lowercased, words: ["alone", "no one", "nobody", "lonely"]) {
            return CompanionReply(
                reply: "\(profile.displayName), being alone with this can make the ache feel enormous. I am here with you right now, and you are not wrong for needing a voice. For this next minute, tell me where you are sitting and whether your body feels tense, heavy, shaky, or numb.",
                suggestedAction: nil
            )
        }

        if containsAny(lowercased, words: ["panic", "panicking", "can't breathe", "cant breathe", "spiraling", "spiral"]) {
            return CompanionReply(
                reply: "Stay with my voice, \(profile.displayName). You do not have to figure out \(personName) right now. Unclench your jaw if you can. Breathe out longer than you breathe in. Then tell me: is this fear, grief, shame, or the urge to do something?",
                suggestedAction: "breathing"
            )
        }

        if containsAny(lowercased, words: ["text", "call", "reach out", "message"]) {
            let boundary = profile.contactGoals.isEmpty ? "the boundary you want" : profile.contactGoals.sorted().joined(separator: ", ")
            return CompanionReply(
                reply: "\(profile.displayName), pause with me. Your goal is \(boundary). What are you hoping contact with \(personName) will give you tonight?",
                suggestedAction: "delay_timer"
            )
        }

        if containsAny(lowercased, words: ["liked", "story", "profile", "social", "seen"]) {
            return CompanionReply(
                reply: "That is a real trigger. What it proves may be small. What it touches in you may be much bigger. What do you know for sure?",
                suggestedAction: "facts_hopes_fears"
            )
        }

        if containsAny(lowercased, words: ["miss", "lonely", "want them", "need them"]) {
            if !profile.currentHurt.isEmpty {
                return CompanionReply(
                    reply: "This touches the part you said hurts most: \(profile.currentHurt). I will not talk you out of missing \(personName). Are you missing the whole reality, or the version you keep replaying?",
                    suggestedAction: nil
                )
            }
            return CompanionReply(
                reply: "Missing \(personName) makes sense. It still does not mean contact is the next move. Which part are you missing: comfort, certainty, touch, apology, or the old routine?",
                suggestedAction: nil
            )
        }

        if containsAny(lowercased, words: ["slipped", "replied", "checked", "saw them"]) {
            return CompanionReply(
                reply: "\(profile.displayName), this does not erase your progress. Tell me exactly what happened with \(personName) first, then we can decide whether anything about the streak or contact plan actually needs to change.",
                suggestedAction: "slip_review"
            )
        }

        if let relevantMemory {
            return CompanionReply(
                reply: "I am using something you actually told me: \(relevantMemory.content) Given that, what is the next action that protects \(profile.displayName) for the next ten minutes?",
                suggestedAction: nil
            )
        }

        if containsAny(lowercased, words: ["why", "what if", "do they", "does he", "does she"]) {
            return CompanionReply(
                reply: "We can separate this into facts, hopes, and fears. I cannot know what \(personName) intends without direct evidence. In the story you told me, what is the clearest fact you have?",
                suggestedAction: nil
            )
        }

        if profile.personName.isEmpty {
            return CompanionReply(
                reply: "\(profile.displayName), stay with this for one more sentence. What part feels most urgent right now?",
                suggestedAction: nil
            )
        }

        return CompanionReply(
            reply: "\(profile.displayName), I know this is connected to \(personName). \(profile.personalAcheLine) Use one sentence for the fact, and one sentence for the meaning your mind is adding to it.",
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
    let isRemembered: Bool
    let sendSuggestedReply: (String) -> Void
    let togglePinned: () -> Void
    let rememberMessage: () -> Void
    let forgetMessage: () -> Void
    let deleteMessage: () -> Void
    @State private var isExpanded = false

    private var shouldCollapse: Bool {
        message.role == .companion && message.text.count > 180
    }

    private var displayedText: String {
        guard shouldCollapse && !isExpanded else { return message.text }
        let index = message.text.index(message.text.startIndex, offsetBy: min(160, message.text.count))
        return String(message.text[..<index]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

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
                Text(displayedText)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(message.role == .user ? Color(hex: "2C211B") : palette.primaryText)
                    .lineSpacing(4)
                if shouldCollapse {
                    Button(isExpanded ? "Less" : "More") {
                        withAnimation(.easeInOut) {
                            isExpanded.toggle()
                        }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.accent)
                    .buttonStyle(.plain)
                }
                if message.role == .companion && !message.suggestedReplies.isEmpty {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(message.suggestedReplies, id: \.self) { reply in
                            Button {
                                sendSuggestedReply(reply)
                            } label: {
                                Text(reply)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(palette.primaryText)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(palette.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                }
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

            Button(action: isRemembered ? forgetMessage : rememberMessage) {
                Label(isRemembered ? "Forget this" : "Remember this", systemImage: isRemembered ? "brain.head.profile.fill" : "brain.head.profile")
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
    @State private var silenceTask: Task<Void, Never>?

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
        .onDisappear {
            silenceTask?.cancel()
            silenceTask = nil
            speechService.cancelRecording()
        }
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
                scheduleSilenceAutoSend()
            }
            isRecording = true
        } catch {
            isRecording = false
            speechStatus = error.localizedDescription
        }
    }

    private func stopRecording() async {
        silenceTask?.cancel()
        silenceTask = nil
        do {
            let transcript = try await speechService.stopRecording()
            draft = transcript
            speechStatus = "Sending..."
            send()
        } catch {
            speechStatus = error.localizedDescription
        }
        isRecording = false
    }

    private func scheduleSilenceAutoSend() {
        silenceTask?.cancel()
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        silenceTask = Task {
            try? await Task.sleep(for: .milliseconds(1300))
            guard !Task.isCancelled else { return }
            await stopRecording()
        }
    }
}

struct BuddyCallView: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @AppStorage("storedChatMessages") private var storedChatMessages = ""
    @AppStorage("storedMemoryItems") private var storedMemoryItems = ""
    @AppStorage(JourneyState.storageKey) private var storedJourneyState = ""
    @AppStorage("autoListenAfterMaraSpeaks") private var autoListenAfterMaraSpeaks = false
    let profile: AppProfile
    var contextTitle: String? = nil
    var openingPrompt: String? = nil
    @State private var speechService = AppleSpeechRecognitionService()
    @State private var messages: [ChatBubbleModel] = []
    @State private var memories: [MemoryRecord] = []
    @State private var transcript = ""
    @State private var callStatus = "Connected"
    @State private var isRecording = false
    @State private var isThinking = false
    @State private var isVoiceLoading = false
    @State private var didStartCall = false
    @State private var showingCrisisSupport = false
    @State private var showingRecentCallHistory = false
    @State private var silenceTask: Task<Void, Never>?
    @State private var deepReplyTask: Task<Void, Never>?
    private let engine = CompanionEngine()

    private var visibleMessages: [ChatBubbleModel] {
        messages.filter { !$0.isDeleted }.suffix(6)
    }

    private var lastBuddyReply: String? {
        messages.last { $0.role == .companion && !$0.isDeleted }?.text
    }

    var body: some View {
        WarmScreen {
            VStack(spacing: 0) {
                callHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                ScrollView {
                    VStack(spacing: 14) {
                        CompanionCharacter(state: companionState, size: 210)
                            .padding(.top, 18)
                            .padding(.bottom, 2)

                        Text(profile.companionDisplayName)
                            .font(.system(size: 44, weight: .semibold, design: .serif))
                            .foregroundStyle(palette.primaryText)

                        if let contextTitle {
                            Text(contextTitle)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(palette.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        Text(callStatus)
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                            .multilineTextAlignment(.center)

                        if isVoiceLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Voice is warming up")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(palette.secondaryText)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(palette.card.opacity(0.72))
                            .clipShape(Capsule())
                        }

                        buddyReplyPanel
                            .padding(.horizontal, 24)
                            .padding(.top, 6)

                        BreathingPacer()
                            .padding(.horizontal, 24)

                        currentTranscript
                            .padding(.horizontal, 24)

                        quickSupportPrompts
                            .padding(.horizontal, 24)

                        recentHistoryToggle
                            .padding(.horizontal, 24)

                        if showingRecentCallHistory {
                            recentCallHistory
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 18)
                }

                callControls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
        .onAppear(perform: loadCallState)
        .onChange(of: messages) { _, newValue in
            storedChatMessages = LocalPersistence.encode(newValue)
        }
        .onChange(of: memories) { _, newValue in
            storedMemoryItems = LocalPersistence.encode(newValue)
        }
    }

    private var callHeader: some View {
        HStack {
            Button {
                endCall()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                    Text("Back")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 14)
                .frame(height: 42)
                .foregroundStyle(palette.primaryText)
                .background(palette.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(palette.divider, lineWidth: 1))
            }
            .accessibilityLabel("Back")

            Spacer(minLength: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text("In-app call")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                Text("I am here.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 10)

            Button {
                endCall()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                    Text("End")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 14)
                .frame(height: 42)
                .foregroundStyle(palette.primaryText)
                .background(palette.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(palette.divider, lineWidth: 1))
            }
            .accessibilityLabel("End call")
        }
    }

    private var currentTranscript: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isRecording ? "Listening now" : "What you said")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(palette.secondaryText)
            Text(transcriptPlaceholder)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(transcript.isEmpty ? palette.secondaryText : palette.primaryText)
                .lineSpacing(5)
                .lineLimit(transcript.isEmpty ? 3 : 5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.divider, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var buddyReplyPanel: some View {
        if let lastBuddyReply {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.accent)
                    Text(profile.companionDisplayName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                    Spacer()
                }
                Text(lastBuddyReply)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(18)
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(palette.accent.opacity(0.65), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var recentHistoryToggle: some View {
        if !visibleMessages.isEmpty {
            Button {
                withAnimation(.easeInOut) {
                    showingRecentCallHistory.toggle()
                }
            } label: {
                HStack {
                    Text(showingRecentCallHistory ? "Hide" : "Recent")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Spacer()
                    Image(systemName: showingRecentCallHistory ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(palette.secondaryText)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(palette.card.opacity(0.7))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var recentCallHistory: some View {
        if !visibleMessages.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                ForEach(visibleMessages) { message in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: message.role == .user ? "person.fill" : "heart.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(message.role == .user ? palette.secondaryText : palette.accent)
                            .frame(width: 18)
                        Text(message.text)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                            .lineLimit(2)
                            .lineSpacing(3)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var transcriptPlaceholder: String {
        if !transcript.isEmpty {
            return transcript
        }
        if contextTitle != nil {
            return "Tap the microphone and let it come out messy. Your words will transcribe here, then \(profile.companionDisplayName) will answer out loud."
        }
        return "Tap the microphone and say what is happening. When you stop, \(profile.companionDisplayName) will answer out loud."
    }

    private var quickSupportPrompts: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No words yet?")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(palette.secondaryText)
            HStack(spacing: 8) {
                quickPromptButton("I feel alone", systemImage: "person.fill.questionmark")
                quickPromptButton("Stay with me", systemImage: "heart.fill")
                quickPromptButton("Breathe with me", systemImage: "lungs.fill")
            }
        }
    }

    private func quickPromptButton(_ title: String, systemImage: String) -> some View {
        Button {
            Task {
                await sendCallMessage(title)
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .foregroundStyle(palette.primaryText)
            .background(palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(palette.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isRecording)
    }

    private var callControls: some View {
        HStack(spacing: 14) {
            Button {
                if let lastBuddyReply {
                    Task {
                        await speakOrShowTextStatus(lastBuddyReply, thenListen: true)
                    }
                }
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(palette.primaryText)
                    .background(palette.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(palette.divider, lineWidth: 1))
            }
            .disabled(lastBuddyReply == nil)
            .accessibilityLabel("Repeat buddy reply")

            Button {
                SpeechPlaybackEngine.shared.stop()
                callStatus = "Voice stopped"
            } label: {
                Image(systemName: "speaker.slash.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(palette.primaryText)
                    .background(palette.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(palette.divider, lineWidth: 1))
            }
            .accessibilityLabel("Stop voice")

            Button {
                Task {
                    if isRecording {
                        await stopAndSend()
                    } else {
                        await startRecording()
                    }
                }
            } label: {
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 28, weight: .bold))
                    .frame(width: 64, height: 64)
                    .foregroundStyle(Color(hex: "2C211B"))
                    .background(isRecording ? palette.blush : palette.accent)
                    .clipShape(Circle())
            }
            .accessibilityLabel(isRecording ? "Stop and send" : "Start talking")

            Button {
                showingCrisisSupport = true
            } label: {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(palette.destructive)
                    .background(palette.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(palette.divider, lineWidth: 1))
            }
            .accessibilityLabel("Get help now")

            Button {
                endCall()
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(Color.white)
                    .background(palette.destructive)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Hang up")
        }
        .sheet(isPresented: $showingCrisisSupport) {
            NavigationStack {
                WarmScreen {
                    VStack(alignment: .leading, spacing: 22) {
                        SheetBackButton(title: "Close") {
                            showingCrisisSupport = false
                        }

                        CompanionCharacter(state: .hardMoment, size: 130)
                            .frame(maxWidth: .infinity)
                        SectionTitle(title: "If this is dangerous", subtitle: "Stay with \(profile.companionDisplayName). Use these only if someone may be hurt right now.")
                        CrisisSupportPanel(profile: profile)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 28)
                }
                .navigationTitle("Safety")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showingCrisisSupport = false }
                    }
                }
            }
        }
    }

    private var safetyReply: String {
        "\(profile.displayName), I am taking this seriously. Stay with me here. Put distance between you and anything you could use to hurt yourself. We are going to talk through the next minute together. If someone may be hurt right now, use the immediate danger button too."
    }

    private var companionState: CompanionState {
        if isRecording { return .listening }
        if isThinking { return .thinking }
        return .speaking
    }

    private func loadCallState() {
        guard !didStartCall else { return }
        didStartCall = true
        messages = LocalPersistence.decode([ChatBubbleModel].self, from: storedChatMessages) ?? []
        memories = seededMemories(existing: LocalPersistence.decode([MemoryRecord].self, from: storedMemoryItems) ?? [], profile: profile)

        let greeting = openingPrompt ?? profile.personalCallGreeting
        messages.append(ChatBubbleModel(role: .companion, text: greeting, sourceMode: "call"))
        Task {
            await SpeechPlaybackEngine.shared.prepareLiveVoice()
            await speakOrShowTextStatus(greeting, thenListen: true)
        }
    }

    private func startRecording() async {
        do {
            transcript = ""
            callStatus = "Listening..."
            showingCrisisSupport = false
            SpeechPlaybackEngine.shared.stop()
            let contextualStrings = [
                profile.displayName,
                profile.rememberedPerson,
                profile.companionDisplayName
            ].filter { !$0.isEmpty && $0 != "there" && $0 != "them" }
            try await speechService.startRecording(contextualStrings: contextualStrings) { partial in
                transcript = partial
                scheduleSilenceAutoSend()
            }
            isRecording = true
        } catch {
            isRecording = false
            callStatus = error.localizedDescription
        }
    }

    private func stopAndSend() async {
        silenceTask?.cancel()
        silenceTask = nil
        do {
            transcript = try await speechService.stopRecording()
            isRecording = false
            await sendTranscript()
        } catch {
            isRecording = false
            callStatus = error.localizedDescription
        }
    }

    private func scheduleSilenceAutoSend() {
        silenceTask?.cancel()
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        silenceTask = Task {
            try? await Task.sleep(for: .milliseconds(1300))
            guard !Task.isCancelled else { return }
            await stopAndSend()
        }
    }

    private func sendTranscript() async {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        await sendCallMessage(trimmed)
    }

    private func sendCallMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = ChatBubbleModel(role: .user, text: trimmed, sourceMode: "call")
        messages.append(userMessage)
        rememberFacts(from: userMessage)
        transcript = ""

        if needsImmediateSafetySupport(trimmed) {
            showingCrisisSupport = true
            let reply = ChatBubbleModel(role: .companion, text: safetyReply, sourceMode: "call")
            messages.append(reply)
            await speakOrShowTextStatus(safetyReply, thenListen: false)
            return
        }

        let immediateReply = immediateCallReply(for: trimmed)
        messages.append(ChatBubbleModel(role: .companion, text: immediateReply, sourceMode: "call"))
        await speakOrShowTextStatus(immediateReply, thenListen: true)

        deepReplyTask?.cancel()
        deepReplyTask = Task {
            isThinking = true
            let response = await engine.reply(
                to: trimmed,
                context: CompanionContext(profile: profile, recentMessages: messages, memories: memories),
                journeyPhase: JourneyState.load(from: storedJourneyState).currentPhase.rawValue
            )
            isThinking = false

            guard !Task.isCancelled else { return }
            guard response.reply != immediateReply else { return }
            messages.append(ChatBubbleModel(role: .companion, text: response.reply, sourceMode: "call"))
            await speakOrShowTextStatus(response.reply, thenListen: false)
        }
    }

    private func immediateCallReply(for text: String) -> String {
        let lowercased = text.lowercased()
        if lowercased.contains("alone") || lowercased.contains("lonely") {
            return "I am right here with you. You do not have to hold this by yourself."
        }
        if lowercased.contains("panic") || lowercased.contains("anxious") || lowercased.contains("scared") {
            return "Stay with me. Slow is enough right now."
        }
        if lowercased.contains("miss") || lowercased.contains("reach out") || lowercased.contains("text them") {
            return "I hear how strong that pull is. Pause with me for one breath."
        }
        return "I hear you. Keep talking to me."
    }

    private func speakOrShowTextStatus(_ text: String, thenListen: Bool) async {
        callStatus = "\(profile.companionDisplayName) answered"
        isVoiceLoading = true

        Task {
            let didSpeak = await SpeechPlaybackEngine.shared.speakLive(text)

            if !didSpeak {
                callStatus = "\(profile.companionDisplayName) is speaking"
                try? await Task.sleep(for: .milliseconds(700))
                _ = await SpeechPlaybackEngine.shared.speakLive(text)
            }

            isVoiceLoading = false

            if thenListen {
                let startedListening = await startListeningIfAllowed()
                if !startedListening {
                    callStatus = "Tap the mic when you are ready"
                }
            } else {
                callStatus = "\(profile.companionDisplayName) is here"
            }
        }
    }

    private func startListeningIfAllowed(delay: Duration = .milliseconds(450)) async -> Bool {
        guard autoListenAfterMaraSpeaks, !isRecording, !isThinking, !showingCrisisSupport else { return false }
        try? await Task.sleep(for: delay)
        guard autoListenAfterMaraSpeaks, !isRecording, !isThinking, !showingCrisisSupport else { return false }
        await startRecording()
        return isRecording
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

    private func needsImmediateSafetySupport(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return [
            "kill myself",
            "end my life",
            "hurt myself",
            "hurt them",
            "suicide",
            "suicidal",
            "can't stay safe",
            "cannot stay safe",
            "not safe",
            "i want to die"
        ].contains { lowercased.contains($0) }
    }

    private func endCall() {
        silenceTask?.cancel()
        silenceTask = nil
        deepReplyTask?.cancel()
        deepReplyTask = nil
        speechService.cancelRecording()
        SpeechPlaybackEngine.shared.stop()
        dismiss()
    }
}

struct CrisisSupportPanel: View {
    @Environment(\.palette) private var palette
    let profile: AppProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("If this is dangerous")
                .font(.system(size: 21, weight: .semibold, design: .serif))
                .foregroundStyle(palette.primaryText)
            Text("Keep talking here with your companion. Use these only if someone may be hurt right now or you need live emergency support.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(palette.secondaryText)
                .lineSpacing(4)
            HStack(spacing: 10) {
                Button {
                    open("tel:911")
                } label: {
                    Label("911", systemImage: "phone.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.white)
                .background(palette.destructive)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    open("tel:988")
                } label: {
                    Label("988", systemImage: "phone.arrow.up.right.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(hex: "2C211B"))
                .background(palette.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    open("sms:988")
                } label: {
                    Label("Text", systemImage: "message.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.plain)
                .foregroundStyle(palette.primaryText)
                .background(palette.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
            }

            if !profile.trustedSupportName.isEmpty || profile.trustedSupportPhoneURL != nil {
                Divider().background(palette.divider)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Reach \(profile.trustedSupportDisplayName)")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(palette.primaryText)
                    Text("\(profile.trustedSupportDisplayName) can be one more human voice in this moment.")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                        .lineSpacing(4)
                    if let phoneURL = profile.trustedSupportPhoneURL {
                        HStack(spacing: 10) {
                            Button {
                                UIApplication.shared.open(phoneURL)
                            } label: {
                                Label("Call", systemImage: "phone.fill")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .frame(maxWidth: .infinity, minHeight: 46)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color(hex: "2C211B"))
                            .background(palette.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            Button {
                                if let messageURL = profile.trustedSupportMessageURL {
                                    UIApplication.shared.open(messageURL)
                                }
                            } label: {
                                Label("Text", systemImage: "message.fill")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .frame(maxWidth: .infinity, minHeight: 46)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(palette.primaryText)
                            .background(palette.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(palette.divider, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.destructive.opacity(0.55), lineWidth: 1)
        )
    }

    private func open(_ value: String) {
        guard let url = URL(string: value) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Hard Moment

struct HardMomentView: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
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
    @State private var showingBuddyCall = false

    var body: some View {
        WarmScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SheetBackButton(title: "Close") {
                        dismiss()
                    }

                    CompanionCharacter(state: .hardMoment, size: 178)
                        .frame(maxWidth: .infinity)
                    SectionTitle(title: "I'm here. What happened?")
                    personalGrounding
                    BreathingPacer()
                    stayWithMeCard

                    if let path {
                        Button {
                            withAnimation(.easeInOut) {
                                self.path = nil
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Choose something else")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(palette.secondaryText)
                        }
                        .buttonStyle(.plain)

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
        .fullScreenCover(isPresented: $showingBuddyCall) {
            BuddyCallView(
                profile: profile,
                contextTitle: "Hard moment",
                openingPrompt: "\(profile.companionDisplayName) here, \(profile.displayName). I am right here with you. \(profile.personalAcheLine) You do not have to explain this perfectly. Start with one sentence, or just say stay with me."
            )
        }
    }

    private var personalGrounding: some View {
        WarmCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("I remember this")
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.primaryText)
                Text(profile.personalAcheLine)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(4)
                Text(profile.boundaryLine)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(4)
                Text(profile.hardBehaviorLine)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(4)
            }
        }
    }

    private var stayWithMeCard: some View {
        WarmCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("You can just talk")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.primaryText)
                Text("If choosing a category is too much, call \(profile.companionDisplayName) and let the messy part come out loud.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(4)
                HStack(spacing: 10) {
                    PrimaryButton(title: "Talk to me", systemImage: "mic.fill") {
                        showingBuddyCall = true
                    }
                    SecondaryButton(title: "Stay with me", systemImage: "heart.fill") {
                        showingBuddyCall = true
                    }
                }
            }
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
                SectionTitle(title: "Stay with me here.", subtitle: "We can talk through the next minute inside this app. If someone may be hurt right now, the immediate-danger options are below.")
                CrisisSupportPanel(profile: profile)
                WarmCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Right now")
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(palette.primaryText)
                        Text("Move away from anything you could use to hurt yourself or someone else. Stay with \(profile.companionDisplayName) here and say one sentence at a time. If someone may be hurt right now, use the immediate-danger options.")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                            .lineSpacing(5)
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
    @AppStorage("storedFeelingCheckIns") private var storedFeelingCheckIns = ""
    @AppStorage("storedProfile") private var storedProfile = ""
    @AppStorage(JourneyState.storageKey) private var storedJourneyState = ""
    @AppStorage("storedJourneyCheckIns") private var storedJourneyCheckIns = ""
    @AppStorage("autoListenAfterMaraSpeaks") private var autoListenAfterMaraSpeaks = false
    @Binding var profile: AppProfile
    @Binding var appearanceMode: String
    @Binding var onboardingCompleted: Bool
    @State private var memories: [MemoryRecord] = []
    @State private var memorySearch = ""

    var body: some View {
        NavigationStack {
            WarmScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        SheetBackButton(title: "Close") {
                            dismiss()
                        }

                        SectionTitle(title: "Settings", subtitle: "Responses are generated on this device. Your history and memories are designed to stay under your control.")

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

                        VoiceSettingsCard()

                        AutoListenConsentCard(isEnabled: $autoListenAfterMaraSpeaks)

                        WarmCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Someone safe")
                                    .font(.system(size: 22, weight: .semibold, design: .serif))
                                    .foregroundStyle(palette.primaryText)
                                Text("Optional. Leave this blank if there is no one personal to call right now.")
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundStyle(palette.secondaryText)
                                    .lineSpacing(4)
                                TextField("Name", text: $profile.trustedSupportName)
                                    .font(.system(size: 17, weight: .regular, design: .rounded))
                                    .padding(14)
                                    .background(palette.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                TextField("Phone", text: $profile.trustedSupportPhone)
                                    .font(.system(size: 17, weight: .regular, design: .rounded))
                                    .keyboardType(.phonePad)
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
                                Text(CompanionEngine.onDeviceModelIsAvailable ? HealYourHeartCopy.onDeviceModelActive : HealYourHeartCopy.onDeviceModelInactive)
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
            memories = seededMemories(existing: decoded, profile: profile)
            return
        }

        memories = seededMemories(existing: [], profile: profile)
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
            journey: JourneyState.load(from: storedJourneyState),
            journeyCheckIns: LocalPersistence.decode([Int: String].self, from: storedJourneyCheckIns) ?? [:],
            feelingCheckIns: LocalPersistence.decode([FeelingCheckIn].self, from: storedFeelingCheckIns) ?? []
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
        storedFeelingCheckIns = ""
        storedJourneyState = ""
        storedJourneyCheckIns = ""
        onboardingCompleted = false
        dismiss()
    }
}

struct VoiceSettingsCard: View {
    @Environment(\.palette) private var palette
    @AppStorage("maraHuggingFaceToken") private var voiceToken = ""
    @State private var isTestingVoice = false
    @State private var voiceStatus = ""

    var body: some View {
        WarmCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Companion voice")
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(palette.primaryText)
                        Text(CompanionVoiceSamplePlayer.clonedVoiceName)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                    }
                    Spacer()
                    Button {
                        CompanionVoiceSamplePlayer.shared.play()
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .foregroundStyle(palette.primaryText)
                            .background(palette.background)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Hear this voice")
                    .buttonStyle(.plain)
                    .disabled(!CompanionVoiceSamplePlayer.hasBundledSample)
                    .opacity(CompanionVoiceSamplePlayer.hasBundledSample ? 1 : 0.45)
                }

                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(palette.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(CompanionVoiceSamplePlayer.clonedVoiceName)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.primaryText)
                        Text("Bundled cloned voice")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                    }
                    Spacer()
                }
                .padding(14)
                .background(palette.background)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(palette.accent, lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Voice key")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                    SecureField("Paste Hugging Face token", text: $voiceToken)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(13)
                        .background(palette.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(palette.divider, lineWidth: 1)
                        )
                    Text("Needed for live Mara voice. The bundled preview still works without it.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                        .lineSpacing(3)
                }

                Button {
                    testLiveVoice()
                } label: {
                    HStack(spacing: 8) {
                        if isTestingVoice {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "speaker.wave.2.fill")
                        }
                        Text(isTestingVoice ? "Testing Mara" : "Test Mara speaking")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundStyle(Color(hex: "2C211B"))
                    .background(palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isTestingVoice)

                if !voiceStatus.isEmpty {
                    Text(voiceStatus)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                        .lineSpacing(3)
                }

                Text(voiceHelpText)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                    .lineSpacing(4)
            }
        }
        .onAppear(perform: applyVoiceToken)
        .onChange(of: voiceToken) { _, _ in
            applyVoiceToken()
        }
    }

    private var voiceHelpText: String {
        if !CompanionVoiceSamplePlayer.hasBundledSample {
            return "The cloned voice sample is missing from the app bundle."
        }

        return "This is the only voice choice in the app."
    }

    private func applyVoiceToken() {
        MaraVoice.shared.useHuggingFace(token: voiceToken)
    }

    private func testLiveVoice() {
        isTestingVoice = true
        voiceStatus = "Asking Mara to speak..."
        applyVoiceToken()
        Task {
            let didSpeak = await SpeechPlaybackEngine.shared.speakLive("I am here with you. You can talk to me.")
            isTestingVoice = false
            voiceStatus = didSpeak ? "Mara spoke." : "Mara could not reach the voice service. Check the token."
        }
    }
}

struct AutoListenConsentCard: View {
    @Environment(\.palette) private var palette
    @Binding var isEnabled: Bool

    var body: some View {
        WarmCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: isEnabled ? "mic.circle.fill" : "mic.slash.circle.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(isEnabled ? palette.accent : palette.secondaryText)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Quick reply mic")
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(palette.primaryText)
                        Text("After Mara answers in a call, open the mic so you can answer without hunting for the button.")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                            .lineSpacing(4)
                    }
                    Spacer()
                    Toggle("", isOn: $isEnabled)
                        .labelsHidden()
                }
                Text(isEnabled ? "You can still stop listening anytime." : "Mara will wait for you to tap the mic.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
            }
        }
    }
}

struct LocalExportBundle: Codable {
    var exportedAt = Date()
    let profile: AppProfile
    let memories: [MemoryRecord]
    let messages: [ChatBubbleModel]
    let contactEvents: [ContactEvent]
    let journey: JourneyState
    let journeyCheckIns: [Int: String]
    let feelingCheckIns: [FeelingCheckIn]
}

struct FeelingCheckIn: Identifiable, Codable, Equatable {
    var id = UUID()
    let optionRawValue: String
    var createdAt = Date()

    init(option: FeelingCheckInOption) {
        self.optionRawValue = option.rawValue
    }
}

enum FeelingCheckInOption: String, CaseIterable, Identifiable, Codable {
    case heavy
    case anxious
    case numb
    case missingThem
    case angry
    case okayish

    var id: String { rawValue }

    var title: String {
        switch self {
        case .heavy: "Heavy"
        case .anxious: "Anxious"
        case .numb: "Numb"
        case .missingThem: "Missing them"
        case .angry: "Angry"
        case .okayish: "Okay-ish"
        }
    }

    var systemImage: String {
        switch self {
        case .heavy: "cloud.fill"
        case .anxious: "waveform.path.ecg"
        case .numb: "moon.zzz.fill"
        case .missingThem: "heart.text.square.fill"
        case .angry: "flame.fill"
        case .okayish: "leaf.fill"
        }
    }

    func openingLine(for profile: AppProfile) -> String {
        switch self {
        case .heavy:
            return "Let it be heavy without carrying it perfectly. Tell me where you feel it most."
        case .anxious:
            return "We can slow the spinning down together. Tell me the thought that keeps looping."
        case .numb:
            return "Numb still counts. You do not have to force tears. Tell me what feels far away."
        case .missingThem:
            return "I remember this is about \(profile.rememberedPerson). Say what you miss, and we will hold it without turning it into a plan."
        case .angry:
            return "Anger can be your body protecting you. Tell me what felt unfair or crossed."
        case .okayish:
            return "Okay-ish is allowed. Tell me what feels a little softer, even if it is small."
        }
    }
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

func seededMemories(existing: [MemoryRecord], profile: AppProfile) -> [MemoryRecord] {
    var memories = existing

    func appendIfMissing(_ memory: MemoryRecord) {
        guard !memories.contains(where: { $0.category == memory.category && $0.subject == memory.subject }) else { return }
        memories.append(memory)
    }

    if !profile.personName.isEmpty {
        appendIfMissing(
            MemoryRecord(
                category: "person",
                subject: profile.personName,
                content: "\(profile.displayName) is healing from \(profile.relationshipSummary).",
                importance: 0.95,
                confidence: 1.0,
                sourceMessageIDs: [],
                isPinned: true
            )
        )
    }

    if !profile.contactGoals.isEmpty {
        appendIfMissing(
            MemoryRecord(
                category: "protection",
                subject: "Contact goal",
                content: profile.boundaryLine,
                importance: 0.9,
                confidence: 1.0,
                sourceMessageIDs: [],
                isPinned: true
            )
        )
    }

    if !profile.currentHurt.isEmpty {
        appendIfMissing(
            MemoryRecord(
                category: "hurt",
                subject: "Hardest part",
                content: profile.personalAcheLine,
                importance: 0.88,
                confidence: 1.0,
                sourceMessageIDs: [],
                isPinned: true
            )
        )
    }

    if !profile.hardBehavior.isEmpty {
        appendIfMissing(
            MemoryRecord(
                category: "hard moment",
                subject: "Likely urge",
                content: profile.hardBehaviorLine,
                importance: 0.84,
                confidence: 1.0,
                sourceMessageIDs: [],
                isPinned: false
            )
        )
    }

    if !profile.trustedSupportName.isEmpty {
        appendIfMissing(
            MemoryRecord(
                category: "support",
                subject: profile.trustedSupportName,
                content: profile.supportLine,
                importance: 0.9,
                confidence: 1.0,
                sourceMessageIDs: [],
                isPinned: true
            )
        )
    }

    return memories
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

        if message.sourceMode == "voice" || message.sourceMode == "call" || message.sourceMode == "quick_prompt" {
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
