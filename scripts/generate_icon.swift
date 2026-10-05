import AppKit

let sizes = [16, 32, 64, 128, 256, 512, 1024]
let iconsetDir = "AppIcon.iconset"

try? FileManager.default.removeItem(atPath: iconsetDir)
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

func createIcon(size: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let inset = CGFloat(size) * 0.05
    let radius = CGFloat(size) * 0.22
    let path = NSBezierPath(roundedRect: rect.insetBy(dx: inset, dy: inset), xRadius: radius, yRadius: radius)

    // Vibrant emerald gradient
    let grad = NSGradient(
        starting: NSColor(calibratedRed: 34/255, green: 197/255, blue: 94/255, alpha: 1.0),
        ending: NSColor(calibratedRed: 16/255, green: 120/255, blue: 60/255, alpha: 1.0)
    )
    grad?.draw(in: path, angle: -45)

    // Integral math symbol
    let fontSize = CGFloat(size) * 0.65
    let font = NSFont(name: "Times-Bold", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let str = NSAttributedString(string: "∫", attributes: [
        .font: font,
        .foregroundColor: NSColor.white
    ])
    let textSize = str.size()
    let textRect = NSRect(
        x: (CGFloat(size) - textSize.width) / 2,
        y: (CGFloat(size) - textSize.height) / 2,
        width: textSize.width,
        height: textSize.height
    )
    str.draw(in: textRect)

    img.unlockFocus()
    return img
}

func savePNG(image: NSImage, path: String, targetSize: Int) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: URL(fileURLWithPath: path))
}

for s in sizes {
    let img1x = createIcon(size: s)
    savePNG(image: img1x, path: "\(iconsetDir)/icon_\(s)x\(s).png", targetSize: s)

    if s <= 512 {
        let img2x = createIcon(size: s * 2)
        savePNG(image: img2x, path: "\(iconsetDir)/icon_\(s)x\(s)@2x.png", targetSize: s * 2)
    }
}

print("Iconset created successfully.")
