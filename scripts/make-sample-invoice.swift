// Renders a sample Argentine "Factura B" for trying the app in the simulator.
// Usage: swift scripts/make-sample-invoice.swift out.jpg && xcrun simctl addmedia booted out.jpg
import AppKit
let size = NSSize(width: 1240, height: 1650)
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
// flip to top-left origin
ctx.translateBy(x: 0, y: size.height); ctx.scaleBy(x: 1, y: -1)
NSColor(white: 0.97, alpha: 1).setFill(); NSRect(origin: .zero, size: size).fill()
func draw(_ s: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, bold: Bool = false) {
    let font = bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(white: 0.1, alpha: 1)]
    let str = NSAttributedString(string: s, attributes: attrs)
    NSGraphicsContext.saveGraphicsState()
    let t = NSAffineTransform(); t.translateX(by: x, yBy: y + size); t.scaleX(by: 1, yBy: -1); t.concat()
    str.draw(at: .zero)
    NSGraphicsContext.restoreGraphicsState()
}
NSColor.black.setStroke()
let box = NSBezierPath(rect: NSRect(x: 570, y: 60, width: 100, height: 110)); box.lineWidth = 3; box.stroke()
draw("B", 597, 68, 72, bold: true)
draw("COD. 06", 585, 175, 18)
draw("ORIGINAL", 1000, 40, 22, bold: true)
draw("FARMACIA DEL CENTRO", 70, 70, 40, bold: true)
draw("Razón Social: Farmacia del Centro S.R.L.", 70, 140, 24)
draw("Domicilio: San Martín 1234 - Santa Fe", 70, 180, 24)
draw("Condición frente al IVA: Responsable Inscripto", 70, 220, 24)
draw("FACTURA", 760, 70, 40, bold: true)
draw("Punto de Venta: 0003  Comp. Nro: 00012345", 760, 140, 22)
draw("Fecha de Emisión: 03/10/2026", 760, 180, 22)
draw("CUIT: 30-71234567-1", 760, 220, 22)
let line = NSBezierPath(); line.move(to: NSPoint(x: 60, y: 290)); line.line(to: NSPoint(x: 1180, y: 290)); line.lineWidth = 2; line.stroke()
draw("Cliente: Consumidor Final", 70, 320, 24)
draw("Producto", 70, 400, 24, bold: true); draw("Cant.", 640, 400, 24, bold: true); draw("Precio", 780, 400, 24, bold: true); draw("Importe", 990, 400, 24, bold: true)
draw("Ibuprofeno 400 mg x 20", 70, 460, 24); draw("2", 660, 460, 24); draw("$ 4.500,00", 780, 460, 24); draw("$ 9.000,00", 990, 460, 24)
draw("Alcohol en gel 250 ml", 70, 510, 24); draw("1", 660, 510, 24); draw("$ 3.250,50", 780, 510, 24); draw("$ 3.250,50", 990, 510, 24)
let line2 = NSBezierPath(); line2.move(to: NSPoint(x: 60, y: 1180)); line2.line(to: NSPoint(x: 1180, y: 1180)); line2.lineWidth = 2; line2.stroke()
draw("Subtotal: $ 12.250,50", 760, 1210, 26)
draw("IVA 21% (incluido): $ 2.126,12", 760, 1260, 26)
draw("TOTAL: $ 12.250,50", 760, 1320, 36, bold: true)
draw("CAE N°: 74123456789012   Vto. CAE: 13/10/2026", 70, 1520, 22)
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
