import AppKit
import ServiceManagement
import SwiftUI

/// All of the app's state. Settings persist; the backdrop itself always starts off.
@MainActor
final class Studio: ObservableObject {
    static let shared = Studio()
    private let defaults = UserDefaults.standard

    @Published var isOn = false {
        didSet {
            wallpaper.setVisible(isOn)
            applyDock()
            if isOn { DesktopPicture.apply(Palette.find(shown)) } else { DesktopPicture.restore(); stage.restore() }
        }
    }
    @Published var paletteID: String { didSet { defaults.set(paletteID, forKey: "palette"); if !cycle { shown = paletteID } } }
    @Published var cycle: Bool { didSet { defaults.set(cycle, forKey: "cycle"); restartCycle() } }
    @Published var motion: Double { didSet { defaults.set(motion, forKey: "motion") } }
    @Published var grain: Bool { didSet { defaults.set(grain, forKey: "grain") } }
    @Published var hideDock: Bool { didSet { defaults.set(hideDock, forKey: "hideDock"); applyDock() } }
    @Published var openAtLogin: Bool {
        didSet {
            do { openAtLogin ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister() }
            catch { NSLog("Backdrop: login item: \(error)") }
        }
    }
    /// The palette on screen right now (differs from `paletteID` while cycling).
    @Published private(set) var shown: String { didSet { if isOn { DesktopPicture.apply(Palette.find(shown)) } } }

    let stage = Stage()
    private lazy var wallpaper = Wallpaper(studio: self)
    private var cycleTimer: Timer?

    private init() {
        defaults.register(defaults: ["palette": "plum", "cycle": false, "motion": 1.0, "grain": true, "hideDock": true])
        paletteID = defaults.string(forKey: "palette") ?? "plum"
        cycle = defaults.bool(forKey: "cycle")
        motion = defaults.double(forKey: "motion")
        grain = defaults.bool(forKey: "grain")
        hideDock = defaults.bool(forKey: "hideDock")
        openAtLogin = SMAppService.mainApp.status == .enabled
        shown = defaults.string(forKey: "palette") ?? "plum"
        Dock.restoreIfLeftHidden()
        DesktopPicture.restore()
        restartCycle()
    }

    func choose(_ palette: Palette) {
        cycle = false
        paletteID = palette.id
        shown = palette.id
    }

    func shutdown() {
        isOn = false
        Dock.restore()
    }

    private func applyDock() {
        if isOn && hideDock { Dock.hide() } else { Dock.restore() }
    }

    private func restartCycle() {
        cycleTimer?.invalidate()
        cycleTimer = nil
        guard cycle else { shown = paletteID; return }
        cycleTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { _ in
            MainActor.assumeIsolated {
                let all = Palette.all.filter(\.cycles)
                let i = all.firstIndex { $0.id == self.shown } ?? 0
                self.shown = all[(i + 1) % all.count].id
            }
        }
    }
}

/// Hides the Dock while recording and puts it back exactly as it was, even after a crash.
enum Dock {
    private static let savedKey = "dockAutohideBefore"

    static func hide() {
        let d = UserDefaults.standard
        if d.object(forKey: savedKey) == nil { d.set(autohide, forKey: savedKey) }
        set(true)
    }

    static func restore() {
        let d = UserDefaults.standard
        guard let before = d.object(forKey: savedKey) as? Bool else { return }
        set(before)
        d.removeObject(forKey: savedKey)
    }

    static func restoreIfLeftHidden() { restore() }

    private static var autohide: Bool {
        CFPreferencesAppSynchronize("com.apple.dock" as CFString)
        return CFPreferencesCopyAppValue("autohide" as CFString, "com.apple.dock" as CFString) as? Bool ?? false
    }

    private static func set(_ on: Bool) {
        guard on != autohide else { return }
        run("/usr/bin/defaults", "write", "com.apple.dock", "autohide", "-bool", on ? "true" : "false")
        run("/usr/bin/killall", "Dock")
    }

    private static func run(_ path: String, _ args: String...) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        try? p.run()
        p.waitUntilExit()
    }
}

/// "Clear the stage": hide every app except the one you're recording, and bring them back after.
@MainActor
final class Stage: ObservableObject {
    @Published private(set) var target: NSRunningApplication?
    @Published private(set) var hidden: [NSRunningApplication] = []

    init() {
        if let app = NSWorkspace.shared.frontmostApplication, Self.counts(app) { target = app }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated {
                if let app, Self.counts(app) { self.target = app }
            }
        }
    }

    func toggle() { hidden.isEmpty ? clear() : restore() }

    private func clear() {
        guard let target else { return }
        hidden = NSWorkspace.shared.runningApplications.filter {
            Self.counts($0) && $0 != target && !$0.isHidden && $0.hide()
        }
        target.activate()
    }

    func restore() {
        hidden.forEach { $0.unhide() }
        hidden = []
    }

    private static func counts(_ app: NSRunningApplication) -> Bool {
        app.activationPolicy == .regular && app.processIdentifier != ProcessInfo.processInfo.processIdentifier
    }
}
