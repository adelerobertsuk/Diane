import SwiftUI

@main
struct DianeApp: App {
    @State private var store = TapeStore.load()

    init() {
        MorningNudge.prepare()
    }

    var body: some Scene {
        WindowGroup {
            PaletteProvider {
                HomeView()
            }
            .environment(store)
        }
    }
}
