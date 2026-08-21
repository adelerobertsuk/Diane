import SwiftUI

struct PagesView: View {
    @Environment(TapeStore.self) private var store
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Tape?
    @State private var openLetter: WeeklyLetter?

    var body: some View {
        NavigationStack {
            List {
                if store.tapes.isEmpty {
                    Text("Nothing on the tape yet. Speak or write once, and it will live here.")
                        .readingStyle(muted: true)
                        .listRowInsets(EdgeInsets(top: 24, leading: Layout.screenInset, bottom: 8, trailing: Layout.screenInset))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }

                if let letter = store.thisWeekLetter {
                    Section {
                        Button {
                            Haptics.light()
                            store.markLetterRead(letter)
                            openLetter = letter
                        } label: {
                            LetterMailRow(
                                unread: letter.isUnread,
                                preview: WeeklyLetterCopy.preview(letter.body)
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: Layout.screenInset, bottom: 8, trailing: Layout.screenInset))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .accessibilityLabel(letter.isUnread ? "New letter to yourself" : "Letter to yourself")
                        .accessibilityHint("Opens the letter")
                    } header: {
                        Text("This week")
                            .kickerStyle()
                    }
                }

                if !store.todayTapes.isEmpty {
                    Section {
                        ForEach(store.todayTapes) { tape in
                            pageRow(tape)
                        }
                    } header: {
                        Text("Today")
                            .kickerStyle()
                    }
                }

                let older = store.recentTapes.filter { !Calendar.current.isDateInToday($0.createdAt) }
                if !older.isEmpty {
                    Section {
                        ForEach(older) { tape in
                            pageRow(tape)
                        }
                    } header: {
                        Text("Pages")
                            .kickerStyle()
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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
            .navigationDestination(item: $openLetter) { letter in
                LetterReadingView(letter: letter)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func pageRow(_ tape: Tape) -> some View {
        Button {
            Haptics.light()
            selected = tape
        } label: {
            HStack(alignment: .center, spacing: 14) {
                CassetteMark(seed: tape.id, written: tape.written)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(tape.displayKicker)
                            .kickerStyle()
                        Spacer(minLength: 8)
                        Text(tape.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(palette.faint)
                            .lineLimit(1)
                            .layoutPriority(1)
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
        .listRowInsets(EdgeInsets(top: 6, leading: Layout.screenInset, bottom: 6, trailing: Layout.screenInset))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Haptics.light()
                store.delete(tape)
            } label: {
                Text("Delete")
            }
        }
    }
}

struct CassetteMark: View {
    @Environment(\.palette) private var palette
    let seed: UUID
    var written: Bool = false

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
        ZStack {
            if written {
                PadMark(seed: seed)
            } else {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 88, height: 58)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(palette.line, lineWidth: 1)
        )
        .shadow(color: palette.ink.opacity(0.12), radius: 8, y: 4)
        .fixedSize()
        .accessibilityHidden(true)
    }
}

private struct PadMark: View {
    let seed: UUID

    private var imageName: String {
        let names = [
            "WrittenNotePin",
            "WrittenNoteTape",
            "WrittenNoteClip",
            "WrittenNotePencilGold",
            "WrittenNotePencilCream",
            "WrittenNotePencilBlue",
            "WrittenNotePencilOlive"
        ]
        let index = Int(seed.hashValue.magnitude % UInt(names.count))
        return names[index]
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
    }
}

private struct LetterMailRow: View {
    @Environment(\.palette) private var palette
    var unread: Bool
    var preview: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            LetterMark()
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("A letter to yourself")
                        .font(.system(size: 16, weight: unread ? .semibold : .medium))
                        .foregroundStyle(palette.ink)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text("This week")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(palette.faint)
                        .lineLimit(1)
                        .layoutPriority(1)
                }
                Text(preview)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(palette.muted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if unread {
                Circle()
                    .fill(palette.accent)
                    .frame(width: 9, height: 9)
                    .accessibilityHidden(true)
            }
        }
        .padding(14)
        .cardBackground()
    }
}

private struct LetterMark: View {
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(palette.card)
            EnvelopeShape()
                .stroke(palette.accent.opacity(0.9), lineWidth: 1.4)
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
        }
        .frame(width: 88, height: 58)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(palette.line, lineWidth: 1)
        )
        .shadow(color: palette.ink.opacity(0.12), radius: 8, y: 4)
        .accessibilityHidden(true)
    }
}

private struct EnvelopeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 1))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY + 2))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 1))
        return path
    }
}

struct LetterReadingView: View {
    @Environment(TapeStore.self) private var store
    @Environment(\.palette) private var palette
    let letter: WeeklyLetter

    var body: some View {
        ScrollView {
            Text(store.presentedLetter(letter))
                .readingStyle()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Layout.cardPadding)
                .cardBackground()
                .padding(.horizontal, Layout.screenInset)
                .padding(.top, 12)
                .padding(.bottom, 36)
        }
        .sanctuaryBackground()
        .navigationTitle("This week")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
