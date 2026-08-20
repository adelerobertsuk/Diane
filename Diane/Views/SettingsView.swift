import SwiftUI

struct SettingsView: View {
    @Environment(TapeStore.self) private var store
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("The tape")
                        .kickerStyle()
                        .padding(.leading, 4)

                    SkinFrame(imageName: store.skin.pickerImageName, selected: true)
                        .frame(height: 260)
                        .shadow(color: palette.ink.opacity(0.1), radius: 20, y: 12)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ],
                        spacing: 12
                    ) {
                        ForEach(TapeSkin.allCases) { skin in
                            Button {
                                Haptics.light()
                                store.chooseSkin(skin)
                            } label: {
                                VStack(spacing: 8) {
                                    SkinFrame(
                                        imageName: skin.pickerImageName,
                                        selected: store.skin == skin
                                    )
                                    .frame(height: 140)
                                    Text(skin.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(palette.ink)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text(store.skin.blurb)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(palette.muted)
                        .padding(.leading, 4)

                    Text("You")
                        .kickerStyle()
                        .padding(.leading, 4)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 0) {
                        TextField("Your name", text: nameBinding)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(palette.ink)
                            .textInputAutocapitalization(.words)
                            .padding(Layout.cardPadding)
                        Divider().overlay(palette.line)
                        TextField("A little about you", text: aboutBinding, axis: .vertical)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(palette.ink)
                            .lineLimit(3...6)
                            .padding(Layout.cardPadding)
                    }
                    .cardBackground()

                    Text("Stays on this phone. The weekly letter uses it. We do not read your Contacts.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(palette.muted)
                        .padding(.horizontal, 4)

                    Text("The morning")
                        .kickerStyle()
                        .padding(.leading, 4)
                        .padding(.top, 8)

                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Wake with Diane")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(palette.ink)
                                Text("A quiet tap so you stay a minute before you go. If it does not arrive, iPhone Settings, Notifications, Diane, Allow.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(palette.muted)
                            }
                            Spacer()
                            SanctuaryToggle(isOn: reminderBinding)
                        }
                        .padding(Layout.cardPadding)

                        if store.reminderEnabled {
                            Divider().overlay(palette.line)
                            DatePicker(
                                "Time",
                                selection: timeBinding,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .padding(Layout.cardPadding)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(palette.ink)
                        }
                    }
                    .cardBackground()

                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Show words while talking")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(palette.ink)
                                Text("Off by default. The waveform is enough.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(palette.muted)
                            }
                            Spacer()
                            SanctuaryToggle(isOn: wordsBinding)
                        }
                        .padding(Layout.cardPadding)
                    }
                    .cardBackground()

                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Clicks")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(palette.ink)
                                Text("The tape clicks. A short note when the pages land. Never while you talk.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(palette.muted)
                            }
                            Spacer()
                            SanctuaryToggle(isOn: clicksBinding)
                        }
                        .padding(Layout.cardPadding)
                    }
                    .cardBackground()

                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Keep the voice")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(palette.ink)
                                Text("On, the sound sits with the pages. Off, only the words. Nothing is uploaded.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(palette.muted)
                            }
                            Spacer()
                            SanctuaryToggle(isOn: voiceBinding)
                        }
                        .padding(Layout.cardPadding)
                    }
                    .cardBackground()

                    Text("Nothing is uploaded. The voice stays on this phone, with the words.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(palette.muted)
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                }
                .padding(.horizontal, Layout.screenInset)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
            .sanctuaryBackground()
            .navigationTitle("Diane")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(palette.ink)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { store.reminderEnabled },
            set: { store.setReminder(enabled: $0, hour: store.reminderHour, minute: store.reminderMinute) }
        )
    }

    private var wordsBinding: Binding<Bool> {
        Binding(
            get: { store.showWordsWhileTalking },
            set: { store.setShowWords($0) }
        )
    }

    private var clicksBinding: Binding<Bool> {
        Binding(
            get: { store.clicksEnabled },
            set: { store.setClicks($0) }
        )
    }

    private var voiceBinding: Binding<Bool> {
        Binding(
            get: { store.keepVoice },
            set: { store.setKeepVoice($0) }
        )
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { store.displayName },
            set: { store.setDisplayName($0) }
        )
    }

    private var aboutBinding: Binding<String> {
        Binding(
            get: { store.aboutYou },
            set: { store.setAboutYou($0) }
        )
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    from: DateComponents(hour: store.reminderHour, minute: store.reminderMinute)
                ) ?? .now
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                store.setReminder(
                    enabled: store.reminderEnabled,
                    hour: parts.hour ?? 7,
                    minute: parts.minute ?? 30
                )
            }
        )
    }
}

private struct SkinFrame: View {
    @Environment(\.palette) private var palette
    let imageName: String
    var selected: Bool = false

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.bg)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        selected ? palette.accent : palette.line,
                        lineWidth: selected ? 1.5 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
