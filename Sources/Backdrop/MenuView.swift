import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var studio: Studio
    @EnvironmentObject private var stage: Stage

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            swatches
            Divider()
            settings
            stageButton
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 300)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Backdrop").font(.system(size: 15, weight: .semibold))
                Text(studio.isOn ? "Moving, over your desktop" : studio.useAsWallpaper ? "Still, as your wallpaper" : "Off")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $studio.isOn).toggleStyle(.switch).labelsHidden()
        }
    }

    private var swatches: some View {
        TimelineView(.animation) { tl in
            let phase = Clock.shared.phase(at: tl.date, speed: max(studio.motion, 0.4))
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Palette.all) { p in
                    Swatch(name: p.name, selected: !studio.cycle && studio.paletteID == p.id) {
                        BackdropView(palette: p, phase: phase)
                    } action: { studio.choose(p) }
                }
                Swatch(name: "Cycle", selected: studio.cycle) {
                    ZStack {
                        BackdropView(palette: Palette.find(studio.shown), phase: phase)
                            .id(studio.shown)
                            .transition(.opacity)
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                    .animation(.easeInOut(duration: 1.2), value: studio.shown)
                } action: { studio.cycle = true }
            }
        }
    }

    private var settings: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Text("Motion")
                Spacer(minLength: 12)
                Image(systemName: "tortoise.fill").foregroundStyle(.tertiary)
                Slider(value: $studio.motion, in: 0...2).frame(width: 120).controlSize(.small)
                Image(systemName: "hare.fill").foregroundStyle(.tertiary)
            }
            row("Film grain", $studio.grain)
            row("Use as wallpaper", $studio.useAsWallpaper)
            row("Hide the Dock while on", $studio.hideDock)
            row("Open at login", $studio.openAtLogin)
        }
        .font(.system(size: 13))
    }

    private func row(_ title: String, _ value: Binding<Bool>) -> some View {
        HStack {
            Text(title)
            Spacer()
            Toggle("", isOn: value).toggleStyle(.switch).controlSize(.mini).labelsHidden()
        }
    }

    private var stageButton: some View {
        Button(action: stage.toggle) {
            HStack(spacing: 8) {
                Image(systemName: stage.hidden.isEmpty ? "macwindow" : "macwindow.on.rectangle")
                    .frame(width: 18)
                Text(stageTitle).lineLimit(1)
                Spacer()
            }
            .font(.system(size: 13, weight: .medium))
            .padding(.vertical, 9)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(.quaternary.opacity(0.7)))
        }
        .buttonStyle(.plain)
        .disabled(stage.hidden.isEmpty && stage.target == nil)
    }

    private var stageTitle: String {
        if !stage.hidden.isEmpty { return "Show the other apps again" }
        guard let name = stage.target?.localizedName else { return "Hide all other apps" }
        return "Hide everything but \(name)"
    }

    private var footer: some View {
        HStack {
            Text("Tip: turn on a Focus so notifications stay quiet.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .keyboardShortcut("q")
        }
    }
}

private struct Swatch<Content: View>: View {
    let name: String
    let selected: Bool
    @ViewBuilder let content: Content
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                content
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.primary.opacity(0.08), lineWidth: 1))
                    .padding(3)
                    .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2))
                Text(name)
                    .font(.system(size: 11, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? .primary : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
