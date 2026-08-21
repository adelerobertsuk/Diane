import SwiftUI

struct WritePagesView: View {
    @Environment(TapeStore.self) private var store
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var openedAt = Date()
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    private var canSave: Bool {
        !store.isSaving && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(store.hasMorningPagesToday ? "A later page" : "Morning pages")
                    .kickerStyle()
                    .padding(.horizontal, 6)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                        .fill(palette.card)

                    if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("If you cannot speak, write.")
                            .font(.system(size: 17, weight: .regular, design: .serif))
                            .foregroundStyle(palette.faint)
                            .padding(.horizontal, 18)
                            .padding(.top, 18)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $draft)
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundStyle(palette.ink)
                        .tint(palette.accent)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .focused($focused)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                        .strokeBorder(palette.line, lineWidth: 1)
                )
                .shadow(color: palette.ink.opacity(0.08), radius: 20, y: 16)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(palette.ink)
                        .padding(.horizontal, 6)
                }
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
                    .disabled(!canSave)
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
                .background(palette.bg.opacity(0.96))
            }
            .sanctuaryBackground()
            .navigationTitle("Write")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        Haptics.light()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(palette.ink)
                    .disabled(store.isSaving)
                }
            }
            .onAppear {
                openedAt = Date()
                errorMessage = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    focused = true
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(store.isSaving)
    }

    private func save() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        errorMessage = nil
        let duration = max(0, Date().timeIntervalSince(openedAt))
        await store.saveTape(transcript: text, duration: duration, voice: nil, written: true)
        if store.tapes.first?.transcript == text {
            dismiss()
        } else {
            errorMessage = "Could not save that page. Try again."
        }
    }
}
