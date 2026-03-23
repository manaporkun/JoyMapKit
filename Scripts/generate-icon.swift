#!/usr/bin/env swift
// generate-icon.swift
// Generates a macOS .icns app icon for JoyMapKit.
// Usage: swift Scripts/generate-icon.swift

import AppKit
import Foundation

// ---------------------------------------------------------------------------
// MARK: - Bootstrap AppKit for headless script usage
// ---------------------------------------------------------------------------

let _ = NSApplication.shared

// ---------------------------------------------------------------------------
// MARK: - Color helpers
// ---------------------------------------------------------------------------

func hex(_ hex: UInt32, alpha: CGFloat = 1.0) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255.0,
        green: CGFloat((hex >> 8) & 0xFF) / 255.0,
        blue: CGFloat(hex & 0xFF) / 255.0,
        alpha: alpha
    )
}

// ---------------------------------------------------------------------------
// MARK: - Drawing
// ---------------------------------------------------------------------------

/// Draw the JoyMapKit icon into the current NSGraphicsContext at the given
/// pixel size.  Every coordinate is expressed as a fraction of `size` so the
/// drawing scales uniformly.
func drawIcon(size: CGFloat) {
    let s = size                       // shorthand
    let isSmall = size <= 32           // skip fine detail at tiny sizes
    let isTiny  = size <= 16

    // ---- Background rounded-rect with gradient ----
    let cornerRadius = s * 0.18
    let bgRect = NSRect(x: 0, y: 0, width: s, height: s)
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)
    bgPath.addClip()

    // Gradient: deep blue -> purple (bottom to top)
    let gradient = NSGradient(
        colors: [hex(0x1a1a2e), hex(0x16213e), hex(0x1a1a40)],
        atLocations: [0.0, 0.55, 1.0],
        colorSpace: .deviceRGB
    )!
    gradient.draw(in: bgRect, angle: 90)

    // ---- Subtle inner glow along the top edge ----
    if !isTiny {
        let glowRect = NSRect(x: 0, y: s * 0.80, width: s, height: s * 0.20)
        let glowGradient = NSGradient(
            starting: NSColor.white.withAlphaComponent(0.12),
            ending: NSColor.white.withAlphaComponent(0.0)
        )!
        glowGradient.draw(in: glowRect, angle: 90)
    }

    // ---- Shadow under gamepad ----
    if !isTiny {
        let shadowColor = NSColor.black.withAlphaComponent(0.35)
        let shadowRect = NSRect(
            x: s * 0.18, y: s * 0.18,
            width: s * 0.64, height: s * 0.10
        )
        let shadowPath = NSBezierPath(ovalIn: shadowRect)
        shadowColor.setFill()
        shadowPath.fill()
    }

    // ---- Gamepad body ----
    let padColor = NSColor.white.withAlphaComponent(0.92)
    let padShadowColor = NSColor(calibratedWhite: 0.75, alpha: 0.80)

    // Body dimensions (centred)
    let bodyW = s * 0.62
    let bodyH = s * 0.30
    let bodyX = (s - bodyW) / 2.0
    let bodyY = s * 0.32

    // Rounded body
    let bodyRect = NSRect(x: bodyX, y: bodyY, width: bodyW, height: bodyH)
    let bodyRadius = bodyH * 0.40
    let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: bodyRadius, yRadius: bodyRadius)

    // Left grip bump
    let gripW = s * 0.14
    let gripH = s * 0.18
    let leftGripRect = NSRect(
        x: bodyX - gripW * 0.10,
        y: bodyY - gripH * 0.55,
        width: gripW,
        height: gripH + bodyH * 0.30
    )
    let leftGripPath = NSBezierPath(roundedRect: leftGripRect, xRadius: gripW * 0.45, yRadius: gripW * 0.45)
    bodyPath.append(leftGripPath)

    // Right grip bump
    let rightGripRect = NSRect(
        x: bodyX + bodyW - gripW * 0.90,
        y: bodyY - gripH * 0.55,
        width: gripW,
        height: gripH + bodyH * 0.30
    )
    let rightGripPath = NSBezierPath(roundedRect: rightGripRect, xRadius: gripW * 0.45, yRadius: gripW * 0.45)
    bodyPath.append(rightGripPath)

    // Draw shadow offset copy first
    if !isTiny {
        NSGraphicsContext.current?.saveGraphicsState()
        let xform = AffineTransform(translationByX: 0, byY: -s * 0.015)
        let shadowBody = bodyPath.copy() as! NSBezierPath
        shadowBody.transform(using: xform)
        padShadowColor.setFill()
        shadowBody.fill()
        NSGraphicsContext.current?.restoreGraphicsState()
    }

    padColor.setFill()
    bodyPath.fill()

    // ---- D-pad (left side) ----
    if !isTiny {
        let dpadCX = bodyX + bodyW * 0.28
        let dpadCY = bodyY + bodyH * 0.52
        let armLen = s * 0.065
        let armThick = s * 0.030

        let dpadColor = hex(0xc0c0c8)
        dpadColor.setFill()

        // Horizontal bar
        let hBar = NSRect(
            x: dpadCX - armLen, y: dpadCY - armThick / 2,
            width: armLen * 2, height: armThick
        )
        NSBezierPath(roundedRect: hBar, xRadius: armThick * 0.25, yRadius: armThick * 0.25).fill()

        // Vertical bar
        let vBar = NSRect(
            x: dpadCX - armThick / 2, y: dpadCY - armLen,
            width: armThick, height: armLen * 2
        )
        NSBezierPath(roundedRect: vBar, xRadius: armThick * 0.25, yRadius: armThick * 0.25).fill()
    }

    // ---- Face buttons – diamond pattern (right side) ----
    if !isTiny {
        let btnCX = bodyX + bodyW * 0.72
        let btnCY = bodyY + bodyH * 0.52
        let btnRadius = s * 0.018
        let spread = s * 0.042

        let btnColor = hex(0xb0b8c8)
        btnColor.setFill()

        let offsets: [(CGFloat, CGFloat)] = [
            (0, spread),       // top
            (0, -spread),      // bottom
            (-spread, 0),      // left
            (spread, 0)        // right
        ]
        for (dx, dy) in offsets {
            let r = NSRect(
                x: btnCX + dx - btnRadius,
                y: btnCY + dy - btnRadius,
                width: btnRadius * 2,
                height: btnRadius * 2
            )
            NSBezierPath(ovalIn: r).fill()
        }
    }

    // ---- Analog sticks (small circles) ----
    if !isSmall {
        let stickRadius = s * 0.025
        let stickColor = hex(0xa0a8b8)
        stickColor.setFill()
        let stickStroke = hex(0x8890a0)
        stickStroke.setStroke()

        // Left stick – slightly above and to the left of D-pad
        let lsCX = bodyX + bodyW * 0.18
        let lsCY = bodyY + bodyH * 0.72
        let lsRect = NSRect(
            x: lsCX - stickRadius, y: lsCY - stickRadius,
            width: stickRadius * 2, height: stickRadius * 2
        )
        let lsPath = NSBezierPath(ovalIn: lsRect)
        lsPath.lineWidth = max(1, s * 0.004)
        lsPath.fill()
        lsPath.stroke()

        // Right stick – slightly below and to the right of face buttons
        let rsCX = bodyX + bodyW * 0.82
        let rsCY = bodyY + bodyH * 0.32
        let rsRect = NSRect(
            x: rsCX - stickRadius, y: rsCY - stickRadius,
            width: stickRadius * 2, height: stickRadius * 2
        )
        let rsPath = NSBezierPath(ovalIn: rsRect)
        rsPath.lineWidth = max(1, s * 0.004)
        rsPath.fill()
        rsPath.stroke()
    }

    // ---- Lightning-bolt accent (mapping motif) ----
    if !isSmall {
        let accentColor = hex(0x4361ee)
        accentColor.setFill()

        // Small lightning bolt to the right of the gamepad body
        let boltCX = s * 0.78
        let boltCY = s * 0.62
        let boltS  = s * 0.06  // scale factor for bolt

        let bolt = NSBezierPath()
        bolt.move(to: NSPoint(x: boltCX - boltS * 0.15, y: boltCY + boltS * 0.5))
        bolt.line(to: NSPoint(x: boltCX + boltS * 0.05, y: boltCY + boltS * 0.05))
        bolt.line(to: NSPoint(x: boltCX + boltS * 0.20, y: boltCY + boltS * 0.10))
        bolt.line(to: NSPoint(x: boltCX + boltS * 0.05, y: boltCY - boltS * 0.5))
        bolt.line(to: NSPoint(x: boltCX - boltS * 0.10, y: boltCY - boltS * 0.02))
        bolt.line(to: NSPoint(x: boltCX - boltS * 0.25, y: boltCY + boltS * 0.02))
        bolt.close()
        bolt.fill()
    }

    // ---- Subtle top-edge highlight on the gamepad body ----
    if !isTiny {
        let highlightRect = NSRect(
            x: bodyX + bodyW * 0.10,
            y: bodyY + bodyH * 0.82,
            width: bodyW * 0.80,
            height: bodyH * 0.12
        )
        let hlPath = NSBezierPath(roundedRect: highlightRect, xRadius: highlightRect.height * 0.5, yRadius: highlightRect.height * 0.5)
        NSColor.white.withAlphaComponent(0.35).setFill()
        hlPath.fill()
    }
}

// ---------------------------------------------------------------------------
// MARK: - Image generation
// ---------------------------------------------------------------------------

/// Render the icon at the requested pixel dimensions and return an NSImage.
func renderIcon(pixelSize: Int) -> NSImage {
    let sz = CGFloat(pixelSize)
    let image = NSImage(size: NSSize(width: sz, height: sz))
    image.lockFocus()

    // Fill with transparent first (safety)
    NSColor.clear.set()
    NSRect(x: 0, y: 0, width: sz, height: sz).fill()

    NSGraphicsContext.current?.saveGraphicsState()
    drawIcon(size: sz)
    NSGraphicsContext.current?.restoreGraphicsState()

    image.unlockFocus()
    return image
}

/// Write an NSImage to a PNG file at `url`.
func writePNG(image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGen", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG data"])
    }
    try png.write(to: url)
}

// ---------------------------------------------------------------------------
// MARK: - Main
// ---------------------------------------------------------------------------

let fileManager = FileManager.default

// Paths
let scriptDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
let projectRoot = scriptDir.deletingLastPathComponent()
let distributionDir = projectRoot.appendingPathComponent("Distribution")
let iconsetDir = distributionDir.appendingPathComponent("AppIcon.iconset")
let icnsPath = distributionDir.appendingPathComponent("AppIcon.icns")

// Create iconset directory
try? fileManager.removeItem(at: iconsetDir)
try fileManager.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

// Standard macOS .iconset sizes and filenames
// Each entry: (filename, pixel size)
let entries: [(String, Int)] = [
    ("icon_16x16.png",        16),
    ("icon_16x16@2x.png",     32),
    ("icon_32x32.png",        32),
    ("icon_32x32@2x.png",     64),
    ("icon_128x128.png",      128),
    ("icon_128x128@2x.png",   256),
    ("icon_256x256.png",      256),
    ("icon_256x256@2x.png",   512),
    ("icon_512x512.png",      512),
    ("icon_512x512@2x.png",   1024),
]

print("Generating icon PNGs...")

// Render unique sizes once and cache them
var cache: [Int: NSImage] = [:]
let uniqueSizes = Set(entries.map { $0.1 }).sorted()
for px in uniqueSizes {
    print("  Rendering \(px)x\(px)...")
    cache[px] = renderIcon(pixelSize: px)
}

// Write PNGs
for (filename, px) in entries {
    let url = iconsetDir.appendingPathComponent(filename)
    guard let image = cache[px] else { continue }
    try writePNG(image: image, to: url)
    print("  Wrote \(filename)")
}

// Run iconutil
print("Running iconutil...")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsPath.path]

let pipe = Pipe()
process.standardError = pipe
process.standardOutput = pipe

try process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    print("iconutil failed (\(process.terminationStatus)): \(output)")
    exit(1)
}

// Clean up iconset directory
try? fileManager.removeItem(at: iconsetDir)

print("Icon generated at: \(icnsPath.path)")
