import SwiftUI

struct TapeDetailView: View {
    @Environment(TapeStore.self) private var store
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    let tape: Tape
    @State private var showLetter = false
    @State private var showTextShare = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(tape.kind.kicker)
                    .kickerStyle()

                Text(tape.createdAt.formatted(.dateTime.weekday(.wide).day().month(.wide).hour().minute()))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(palette.muted)

                if hasDistinctSummary {
                    Text("Summary")
                        .kickerStyle()
                        .padding(.top, 6)

                    Text(tape.summary)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(palette.muted)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Layout.cardPadding)
                        .cardBackground()
                }

                Text("The pages")
                    .kickerStyle()
                    .padding(.top, 8)

                Text("“\(tape.transcript)”")
                    .readingStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Layout.cardPadding)
                    .cardBackground()

                Button("Delete this tape") {
                    Haptics.light()
                    TapeSounds.shared.play(.stop)
                    store.delete(tape)
                    dismiss()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(palette.muted)
                .padding(.top, 8)
            }
            .padding(.horizontal, Layout.screenInset)
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .sanctuaryBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.light()
                    TapeSounds.shared.play(.pages)
                    if TapeLetter.canSend {
                        showLetter = true
                    } else {
                        showTextShare = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(palette.ink)
                }
                .accessibilityLabel("Send a letter")
            }
        }
        .sheet(isPresented: $showLetter) {
            MailLetterView(tape: tape, isPresented: $showLetter)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showTextShare) {
            ShareSheet(items: [tape.shareText])
        }
    }

    private var hasDistinctSummary: Bool {
        tape.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            != tape.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
