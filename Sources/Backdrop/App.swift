import SwiftUI

@main
struct BackdropApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var studio = Studio.shared

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(studio)
                .environmentObject(studio.stage)
        } label: {
            Image(systemName: studio.isOn ? "circle.lefthalf.filled" : "circle.lefthalf.striped.horizontal")
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// `Backdrop --render <dir>` writes a 1920×1080 still of every palette, for checking the look.
    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--render"), i + 1 < args.count else { return }
        MainActor.assumeIsolated {
            for p in Palette.all {
                let view = ZStack { BackdropView(palette: p, phase: 3); GrainView() }.frame(width: 1920, height: 1080)
                let renderer = ImageRenderer(content: view)
                if let cg = renderer.cgImage {
                    let rep = NSBitmapImageRep(cgImage: cg)
                    try? rep.representation(using: .png, properties: [:])?
                        .write(to: URL(fileURLWithPath: args[i + 1]).appendingPathComponent("\(p.id).png"))
                }
            }
        }
        exit(0)
    }

    func applicationWillTerminate(_ notification: Notification) {
        MainActor.assumeIsolated { Studio.shared.shutdown() }
    }
}
