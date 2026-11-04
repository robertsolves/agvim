import Cocoa
import FinderSync

// New AgVim Project, Add to AgVim Project and Copy Directory, directly in Finder's
// right-click menu. Finder runs this in a sandbox, so the first two hand over to the `run` script in Application Scripts,
// which macOS runs outside the sandbox (build.sh puts it there).
@objc(FinderExtension)
final class FinderExtension: FIFinderSync {
  override init() {
    super.init()
    // Finder only shows this menu inside watched folders, so watch everything.
    FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
  }

  override func menu(for menuKind: FIMenuKind) -> NSMenu? {
    guard menuKind == .contextualMenuForItems || menuKind == .contextualMenuForContainer else { return nil }
    let menu = NSMenu(title: "")
    let icon = themed(Bundle(for: FinderExtension.self).image(forResource: "menu-icon"))
    menu.addItem(withTitle: "New AgVim Project", action: #selector(newProject(_:)), keyEquivalent: "").image = icon
    menu.addItem(withTitle: "Add to AgVim Project", action: #selector(addToProject(_:)), keyEquivalent: "").image = icon
    if menuKind == .contextualMenuForItems {
      menu.addItem(withTitle: "Copy Directory", action: #selector(copyDirectory(_:)), keyEquivalent: "").image =
        themed(NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil))
    }
    return menu
  }

  /// Finder draws an extension's images as they arrive, ignoring template images, so an
  /// icon is coloured here each time the menu opens: white on dark menus, black on light.
  private func themed(_ image: NSImage?) -> NSImage? {
    guard let image, image.size.width > 0, image.size.height > 0,
      let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: 32, pixelsHigh: 32, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
      let context = NSGraphicsContext(bitmapImageRep: rep)
    else { return image }
    let dark =
      UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
      || NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    let bounds = NSRect(x: 0, y: 0, width: 32, height: 32)
    let scale = min(32 / image.size.width, 32 / image.size.height)
    let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    image.draw(in: NSRect(x: (32 - size.width) / 2, y: (32 - size.height) / 2, width: size.width, height: size.height))
    (dark ? NSColor.white : NSColor.black).set()
    bounds.fill(using: .sourceIn)
    NSGraphicsContext.restoreGraphicsState()
    let themed = NSImage(size: NSSize(width: 16, height: 16))
    themed.addRepresentation(rep)
    return themed
  }

  @objc func newProject(_ sender: AnyObject?) { run("new") }
  @objc func addToProject(_ sender: AnyObject?) { run("add") }

  @objc func copyDirectory(_ sender: AnyObject?) {
    let items = FIFinderSyncController.default().selectedItemURLs() ?? []
    guard !items.isEmpty else { return }
    var seen = Set<String>()
    let directories = items.map(directoryPath).filter { seen.insert($0).inserted }
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(directories.joined(separator: "\n"), forType: .string)
  }

  /// A folder gives its own path and a file gives its parent folder.
  private func directoryPath(of url: URL) -> String {
    // The sandbox can refuse the lookup, so fall back to the URL's trailing slash.
    let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
    let isDirectory = values?.isDirectory ?? url.hasDirectoryPath
    return isDirectory ? url.path : url.deletingLastPathComponent().path
  }

  private func run(_ action: String) {
    let controller = FIFinderSyncController.default()
    // Right-clicking a folder's background selects nothing: use that folder.
    var items = controller.selectedItemURLs() ?? []
    if items.isEmpty, let folder = controller.targetedURL() { items = [folder] }
    guard !items.isEmpty,
      let scripts = FileManager.default.urls(for: .applicationScriptsDirectory, in: .userDomainMask).first,
      let task = try? NSUserUnixTask(url: scripts.appendingPathComponent("run"))
    else { return }
    task.execute(withArguments: [action] + items.map(\.path), completionHandler: nil)
  }
}
