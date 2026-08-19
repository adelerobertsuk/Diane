import SwiftUI

struct WritePagesView: View {
    @Environment(TapeStore.self) private var store
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var openedAt = Date()
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(store.hasMorningPagesToday ? "A later page" : "Morning pages")
                    .kickerStyle()
                    .padding(.horizontal, 6)

                ZStack(alignment: .topLeading) {
                    if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("If you cannot speak, write.")
                            .font(.system(size: 17, weight: .regular, design: .serif))
                            .foregroundStyle(palette.faint)
                            .padding(.horizontal, 6)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $draft)
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundStyle(palette.ink)
                        .scrollContentBackground(.hidden)
                        .focused($focused)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .padding(Layout.cardPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .cardBackground()
            }
            .padding(.horizontal, Layout.screenInset)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button {
                        Task { await save() }
                    } label: {
                        Text(store.isSaving ? "Writing it down" : "That's it")
                    }
                    .buttonStyle(PillButtonStyle())
                    .disabled(store.isSaving || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, Layout.screenInset)

                    Button("Not this time") {
                        Haptics.light()
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(palette.muted)
                    .disabled(store.isSaving)
                }
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(palette.bg)
            }
            .sanctuaryBackground()
            .navigationTitle("Write")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                openedAt = Date()
                focused = true
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(store.isSaving || !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func save() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let duration = max(0, Date().timeIntervalSince(openedAt))
        await store.saveTape(transcript: text, duration: duration, voice: nil, written: true)
        dismiss()
    }
}
