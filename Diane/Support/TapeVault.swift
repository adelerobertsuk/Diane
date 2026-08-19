import AVFoundation
import Foundation

enum TapeVault {
    static var folder: URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Tapes", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func url(for id: UUID) -> URL {
        folder.appendingPathComponent("\(id.uuidString).m4a")
    }

    static func url(named name: String) -> URL {
        folder.appendingPathComponent(name)
    }

    static func keep(_ source: URL, as id: UUID) -> String? {
        let ext = source.pathExtension.isEmpty ? "m4a" : source.pathExtension
        let dest = folder.appendingPathComponent("\(id.uuidString).\(ext)")
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.moveItem(at: source, to: dest)
            return dest.lastPathComponent
        } catch {
            try? FileManager.default.copyItem(at: source, to: dest)
            try? FileManager.default.removeItem(at: source)
            return FileManager.default.fileExists(atPath: dest.path) ? dest.lastPathComponent : nil
        }
    }

    static func forget(_ name: String?) {
        guard let name, !name.isEmpty else { return }
        try? FileManager.default.removeItem(at: url(named: name))
    }

    static func forget(_ url: URL?) {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Compress a raw CAF take into an m4a that Mail can send.
    static func compact(_ source: URL) async -> URL {
        let dest = source.deletingPathExtension().appendingPathExtension("m4a")
        try? FileManager.default.removeItem(at: dest)
        let asset = AVURLAsset(url: source)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            return source
        }
        do {
            try await session.export(to: dest, as: .m4a)
        } catch {
            return source
        }
        if FileManager.default.fileExists(atPath: dest.path) {
            try? FileManager.default.removeItem(at: source)
            return dest
        }
        return source
    }
}
