import SwiftUI

struct PagesView: View {
    @Environment(TapeStore.self) private var store
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Tape?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if store.tapes.isEmpty {
                        Text("Nothing on the tape yet. Speak once, and it will live here.")
                            .readingStyle(muted: true)
                            .padding(.top, 24)
                    }

                    if let letter = store.thisWeekLetter {
                        Text("This week")
                            .kickerStyle()
                        Text(letter.body)
                            .readingStyle()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Layout.cardPadding)
                            .cardBackground()
                    }

                    if !store.todayTapes.isEmpty {
                        Text("Today")
                            .kickerStyle()
                        ForEach(store.todayTapes) { tape in
                            pageRow(tape)
                        }
                    }

                    let older = store.recentTapes.filter { !Calendar.current.isDateInToday($0.createdAt) }
                    if !older.isEmpty {
                        Text("Pages")
                            .kickerStyle()
                            .padding(.top, 6)
                        ForEach(older) { tape in
                            pageRow(tape)
                        }
                    }
                }
                .padding(.horizontal, Layout.screenInset)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
            .sanctuaryBackground()
            .navigationTitle("Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(palette.ink)
                }
            }
            .navigationDestination(item: $selected) { tape in
                TapeDetailView(tape: tape)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func pageRow(_ tape: Tape) -> some View {
        Button {
            Haptics.light()
            TapeSounds.shared.play(.pages)
            selected = tape
        } label: {
            HStack(alignment: .center, spacing: 14) {
                CassetteMark(seed: tape.id)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(tape.kind.kicker)
                            .kickerStyle()
                        Spacer()
                        Text(tape.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(palette.faint)
                    }
                    Text(tape.summary)
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundStyle(palette.ink)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(14)
            .cardBackground()
        }
        .buttonStyle(.plain)
    }
}

struct CassetteMark: View {
    @Environment(\.palette) private var palette
    let seed: UUID

    private var imageName: String {
        let names = [
            "TapeShellGold",
            "TapeShellPurple",
            "TapeShellRed",
            "TapeShellBlack",
            "TapeShellClear",
            "TapeShellCobalt",
            "TapeShellGreen",
            "TapeShellOrange",
            "TapeShellTeal",
            "TapeShellPink"
        ]
        let index = Int(seed.hashValue.magnitude % UInt(names.count))
        return names[index]
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: 88, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(palette.line, lineWidth: 1)
            )
            .shadow(color: palette.ink.opacity(0.12), radius: 8, y: 4)
            .accessibilityHidden(true)
    }
}
