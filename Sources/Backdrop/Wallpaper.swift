import AppKit
import SwiftUI

/// One borderless window per screen, just above the desktop icons (so they're covered) and below
/// every app window. Clicks pass straight through, and it stays put on every Space.
@MainActor
final class Wallpaper {
    private unowned let studio: Studio
    private var windows: [NSWindow] = []
    private var visible = false

    init(studio: Studio) {
        self.studio = studio
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                guard self.visible else { return }
                self.windows.forEach { $0.orderOut(nil) }
                self.windows = NSScreen.screens.map(self.makeWindow)
                self.windows.forEach { $0.orderFront(nil) }
            }
        }
    }

    func setVisible(_ on: Bool) {
        guard on != visible else { return }
        visible = on
        if on {
            windows = NSScreen.screens.map(makeWindow)
            windows.forEach { $0.alphaValue = 0; $0.orderFront(nil) }
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.9
                windows.forEach { $0.animator().alphaValue = 1 }
            }
        } else {
            let leaving = windows
            windows = []
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.6
                leaving.forEach { $0.animator().alphaValue = 0 }
            }, completionHandler: {
                leaving.forEach { $0.orderOut(nil) }
            })
        }
    }

    private func makeWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.hasShadow = false
        window.backgroundColor = .black
        window.contentView = NSHostingView(rootView: WallpaperView(studio: studio))
        window.setFrame(screen.frame, display: false)
        return window
    }
}

struct WallpaperView: View {
    @ObservedObject var studio: Studio

    var body: some View {
        TimelineView(.animation) { tl in
            let phase = Clock.shared.phase(at: tl.date, speed: studio.motion)
            ZStack {
                BackdropView(palette: Palette.find(studio.shown), phase: phase)
                    .id(studio.shown)
                    .transition(.opacity)
                if studio.grain { GrainView() }
            }
            .compositingGroup()
            .animation(.easeInOut(duration: 4), value: studio.shown)
        }
        .ignoresSafeArea()
    }
}

/// Sets the real desktop picture to a still of a palette, on every screen.
@MainActor
enum DesktopPicture {
    private static let fill: [NSWorkspace.DesktopImageOptionKey: Any] = [
        .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue, .allowClipping: true,
    ]
    private static var folder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Backdrop", isDirectory: true)
    }

    static func apply(_ palette: Palette) {
        let workspace = NSWorkspace.shared
        for screen in NSScreen.screens {
            guard let still = still(of: palette, size: screen.frame.size),
                  workspace.desktopImageURL(for: screen)?.standardizedFileURL != still.standardizedFileURL else { continue }
            try? workspace.setDesktopImageURL(still, for: screen, options: fill)
        }
    }

    private static func still(of palette: Palette, size: CGSize) -> URL? {
        let url = folder.appendingPathComponent("\(palette.id)-\(Int(size.width))x\(Int(size.height)).png")
        if FileManager.default.fileExists(atPath: url.path) { return url }
        let renderer = ImageRenderer(content: BackdropView(palette: palette, phase: 0).frame(width: size.width, height: size.height))
        guard let cg = renderer.cgImage,
              let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else { return nil }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return (try? png.write(to: url)) != nil ? url : nil
    }
}
