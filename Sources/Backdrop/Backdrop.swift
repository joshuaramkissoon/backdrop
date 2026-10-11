import SwiftUI

/// A blurred colour field. Blob geometry is in 1920×1080 design units (left, top, width, height),
/// sampled from the Patch launch video.
struct Palette: Identifiable, Equatable {
    struct Blob: Equatable { let color: Color; let x, y, w, h: Double }
    let id: String
    let name: String
    let base: Color
    let blobs: [Blob]
    var cycles: Bool { id != "ink" }  // keep the dark one out of the light rotation

    static let all: [Palette] = [
        Palette(id: "plum", name: "Plum", base: Color(hex: 0xE9C4BE), blobs: [
            Blob(color: Color(hex: 0x8E3A5C), x: -260, y: 260, w: 1300, h: 1100),
            Blob(color: Color(hex: 0xFF8A73), x: 900, y: -300, w: 1100, h: 900),
            Blob(color: Color(hex: 0x5A2F3D), x: 1100, y: 520, w: 900, h: 800),
        ]),
        // The plum → dusk crossfade.
        Palette(id: "orchid", name: "Orchid", base: Color(hex: 0xCDB0C2), blobs: [
            Blob(color: Color(hex: 0x855987), x: -260, y: 300, w: 1300, h: 1050),
            Blob(color: Color(hex: 0xE8A5A1), x: 950, y: -300, w: 1100, h: 900),
            Blob(color: Color(hex: 0x402B49), x: 1100, y: 540, w: 900, h: 800),
            Blob(color: Color(hex: 0xA99BC0), x: -300, y: -300, w: 1000, h: 750),
        ]),
        Palette(id: "lilac", name: "Lilac", base: Color(hex: 0xC6BED6), blobs: [
            Blob(color: Color(hex: 0x8386BF), x: -300, y: -200, w: 1300, h: 1000),
            Blob(color: Color(hex: 0x37294D), x: 1000, y: 420, w: 1000, h: 900),
            Blob(color: Color(hex: 0xD9C3D2), x: 750, y: -300, w: 1000, h: 750),
            Blob(color: Color(hex: 0xB9ADCB), x: -250, y: 600, w: 1000, h: 700),
        ]),
        Palette(id: "dusk", name: "Dusk", base: Color(hex: 0xC9D2EE), blobs: [
            Blob(color: Color(hex: 0x6C7FC9), x: -300, y: -200, w: 1300, h: 1000),
            Blob(color: Color(hex: 0x2E2B55), x: 1000, y: 400, w: 1000, h: 900),
            Blob(color: Color(hex: 0xE6EBFA), x: 700, y: -300, w: 900, h: 700),
        ]),
        // The dusk → sand crossfade.
        Palette(id: "mist", name: "Mist", base: Color(hex: 0xD9D7DB), blobs: [
            Blob(color: Color(hex: 0xA9AAC4), x: -300, y: -200, w: 1300, h: 1000),
            Blob(color: Color(hex: 0x553C45), x: 1100, y: 560, w: 900, h: 800),
            Blob(color: Color(hex: 0xC9AC9C), x: 900, y: -250, w: 1000, h: 800),
        ]),
        Palette(id: "sand", name: "Sand", base: Color(hex: 0xEAD9C2), blobs: [
            Blob(color: Color(hex: 0xC98E5B), x: 600, y: -200, w: 1300, h: 1000),
            Blob(color: Color(hex: 0xF3E6D4), x: -300, y: 400, w: 1000, h: 900),
            Blob(color: Color(hex: 0x7A4B3A), x: 1200, y: 600, w: 800, h: 700),
        ]),
        // The cream the section resolves into: quiet enough for any demo.
        Palette(id: "porcelain", name: "Porcelain", base: Color(hex: 0xF4EFEC), blobs: [
            Blob(color: Color(hex: 0xE2E0EE), x: -300, y: -250, w: 1200, h: 1000),
            Blob(color: Color(hex: 0xF0DACD), x: 1050, y: 500, w: 1100, h: 900),
            Blob(color: Color(hex: 0xFFFFFF), x: 550, y: 200, w: 900, h: 700),
        ]),
        Palette(id: "ink", name: "Ink", base: Color(hex: 0x17131D), blobs: [
            Blob(color: Color(hex: 0x4A2F6B), x: -200, y: -150, w: 1200, h: 1000),
            Blob(color: Color(hex: 0x1E3A5A), x: 1000, y: 450, w: 1100, h: 900),
            Blob(color: Color(hex: 0x7A2E4A), x: 900, y: -250, w: 800, h: 700),
        ]),
    ]

    static func find(_ id: String) -> Palette { all.first { $0.id == id } ?? all[0] }
}

/// Shared drift phase, advanced by elapsed time × speed so changing speed never makes the blobs jump.
final class Clock {
    static let shared = Clock()
    private var last: Date?
    private var phase = 0.0

    func phase(at date: Date, speed: Double) -> Double {
        if let last, date > last { phase += min(date.timeIntervalSince(last), 0.1) * speed }
        if last == nil || date > last! { last = date }
        return phase
    }
}

struct BackdropView: View {
    let palette: Palette
    let phase: Double

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.base))
            let sx = size.width / 1920, sy = size.height / 1080
            let sigma = 134 * sx  // the video's blur(110px), softened slightly
            for (i, b) in palette.blobs.enumerated() {
                // Each blob wanders on its own slow Lissajous path.
                let k = Double(i)
                let fx = 1 / (17 + k * 2.3), fy = 1 / (21 + k * 1.7), p = k * 1.9
                let dx = sin(phase * 2 * .pi * fx + p) * (6 + k * 1.5) / 100 * size.width
                let dy = cos(phase * 2 * .pi * fy + p * 0.7) * (5 + k * 1.8) / 100 * size.height
                let s = 1 + sin(phase * 2 * .pi * fx * 0.6 + p) * 0.06
                let rx = b.w / 2 * sx * s, ry = b.h / 2 * sy * s
                let outer = rx + 3 * sigma

                var c = ctx
                c.translateBy(x: (b.x + b.w / 2) * sx + dx, y: (b.y + b.h / 2) * sy + dy)
                c.scaleBy(x: 1, y: ry / rx)
                c.fill(Path(ellipseIn: CGRect(x: -outer, y: -outer, width: outer * 2, height: outer * 2)),
                       with: .radialGradient(Self.blurredDisc(b.color, radius: rx, sigma: sigma, outer: outer),
                                             center: .zero, startRadius: 0, endRadius: outer))
            }
        }
    }

    /// The falloff of a disc under a Gaussian blur, as gradient stops: same look as CSS blur, no blur pass.
    private static func blurredDisc(_ color: Color, radius: Double, sigma: Double, outer: Double) -> Gradient {
        Gradient(stops: (0...16).map { n in
            let t = Double(n) / 16
            let a = 0.5 * erfc((t * outer - radius) / (sigma * 2.0.squareRoot()))
            return .init(color: color.opacity(a), location: t)
        })
    }
}

/// Fine static grain; keeps the gradients from banding once a recording is compressed.
struct GrainView: View {
    private static let image: NSImage = {
        let n = 128
        let bytes = (0..<n * n).map { _ in UInt8.random(in: 0...255) }
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        let cg = CGImage(width: n, height: n, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: n,
                         space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
                         provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        return NSImage(cgImage: cg, size: NSSize(width: n / 2, height: n / 2))
    }()

    var body: some View {
        Image(nsImage: Self.image)
            .resizable(resizingMode: .tile)
            .opacity(0.09)
            .blendMode(.overlay)
            .allowsHitTesting(false)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
