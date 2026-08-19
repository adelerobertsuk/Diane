import SwiftUI

struct PagesView: View {
    @Environment(TapeStore.self) private var store
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Tape?

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
                        Text(store.presentedLetter(letter))
                            .readingStyle()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Layout.cardPadding)
                            .cardBackground()
                            .listRowInsets(EdgeInsets(top: 4, leading: Layout.screenInset, bottom: 8, trailing: Layout.screenInset))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
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
    @Environment(\.palette) private var palette
    let seed: UUID

    private var band: Color {
        let bands = [palette.rec, palette.pause, palette.accent, palette.ink, palette.muted]
        let index = Int(seed.hashValue.magnitude % UInt(bands.count))
        return bands[index]
    }

    var body: some View {
        ZStack(alignment: .top) {
            palette.card
            VStack(spacing: 0) {
                Rectangle()
                    .fill(band)
                    .frame(height: 5)
                VStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(palette.ink.opacity(0.12))
                            .frame(height: 1)
                    }
                }
                .padding(.horizontal, 9)
                .padding(.top, 10)
                Spacer(minLength: 0)
            }
        }
        .frame(width: 88, height: 58)
    }
}
