import AppKit
import CoreGraphics
import Foundation

private struct Resolution {
    let width: Int
    let height: Int

    var key: String { "\(width)x\(height)" }
    var title: String { "\(width) × \(height)" }
}

private final class CrosshairPreview: NSView {
    var crosshairColor: NSColor = .white { didSet { needsDisplay = true } }
    var barSize = 5 { didSet { needsDisplay = true } }
    var gap = 1 { didSet { needsDisplay = true } }
    var thickness = 1 { didSet { needsDisplay = true } }
    var opacity = 100 { didSet { needsDisplay = true } }
    var showsDot = false { didSet { needsDisplay = true } }
    var showsOutline = true { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor(calibratedWhite: 0.20, alpha: 1).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8).fill()

        let x = bounds.midX
        let y = bounds.midY
        let length = CGFloat(barSize * 2)
        let separation = CGFloat((gap + 4) * 2)
        let width = CGFloat(max(thickness, 1) * 2)
        let half = width / 2
        var bars = [
            NSRect(x: x - separation - length, y: y - half, width: length, height: width),
            NSRect(x: x + separation, y: y - half, width: length, height: width),
            NSRect(x: x - half, y: y + separation, width: width, height: length),
            NSRect(x: x - half, y: y - separation - length, width: width, height: length),
        ]
        if showsDot {
            bars.append(NSRect(x: x - half, y: y - half, width: width, height: width))
        }

        let alpha = CGFloat(opacity) / 100
        for bar in bars {
            if showsOutline {
                NSColor.black.withAlphaComponent(alpha).setFill()
                NSBezierPath(rect: bar.insetBy(dx: -1, dy: -1)).fill()
            }
            crosshairColor.withAlphaComponent(alpha).setFill()
            NSBezierPath(rect: bar).fill()
        }
    }
}

@main
final class LauncherApp: NSObject, NSApplicationDelegate {
    private let defaults = UserDefaults.standard
    private let mapPopup = NSPopUpButton()
    private let botCountPopup = NSPopUpButton()
    private let difficultyPopup = NSPopUpButton()
    private let resolutionPopup = NSPopUpButton()
    private let fullscreenCheckbox = NSButton(checkboxWithTitle: "Fullscreen", target: nil, action: nil)
    private let graphicsButton = NSButton(title: "Graphics Settings…", target: nil, action: nil)
    private let texturePopup = NSPopUpButton()
    private let filteringPopup = NSPopUpButton()
    private let antialiasingPopup = NSPopUpButton()
    private let shadowsPopup = NSPopUpButton()
    private let shadersPopup = NSPopUpButton()
    private let vsyncCheckbox = NSButton(checkboxWithTitle: "Limit frames to display refresh", target: nil, action: nil)
    private let colorWell = NSColorWell()
    private let sizeSlider = NSSlider(value: 5, minValue: 1, maxValue: 20, target: nil, action: nil)
    private let gapSlider = NSSlider(value: 1, minValue: 0, maxValue: 15, target: nil, action: nil)
    private let thicknessSlider = NSSlider(value: 1, minValue: 1, maxValue: 6, target: nil, action: nil)
    private let opacitySlider = NSSlider(value: 100, minValue: 20, maxValue: 100, target: nil, action: nil)
    private let dotCheckbox = NSButton(checkboxWithTitle: "Center dot", target: nil, action: nil)
    private let outlineCheckbox = NSButton(checkboxWithTitle: "Black outline", target: nil, action: nil)
    private let sizeValue = NSTextField(labelWithString: "5")
    private let gapValue = NSTextField(labelWithString: "1")
    private let thicknessValue = NSTextField(labelWithString: "1")
    private let opacityValue = NSTextField(labelWithString: "100%")
    private let preview = CrosshairPreview()
    private let launchButton = NSButton(title: "Launch Game", target: nil, action: nil)
    private let statusLabel = NSTextField(labelWithString: "Choose settings, then launch.")
    private var resolutions: [Resolution] = []
    private var window: NSWindow!
    private var graphicsWindow: NSPanel?
    private var gameProcess: Process?

    private var gameRoot: URL {
        Bundle.main.bundleURL.deletingLastPathComponent().standardizedFileURL
    }

    static func main() {
        let app = NSApplication.shared
        let delegate = LauncherApp()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenus()
        restoreSettings()
        buildWindow()
        refreshPreview()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func buildMenus() {
        let mapsDirectory = gameRoot.appendingPathComponent("csgo/maps", isDirectory: true)
        let mapFiles = (try? FileManager.default.contentsOfDirectory(at: mapsDirectory, includingPropertiesForKeys: nil)) ?? []
        let maps = mapFiles.filter { $0.pathExtension.lowercased() == "bsp" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
        mapPopup.addItems(withTitles: maps)

        for count in 0...20 {
            botCountPopup.addItem(withTitle: count == 0 ? "0 (solo)" : "\(count)")
        }
        difficultyPopup.addItems(withTitles: ["Easy", "Normal", "Hard", "Expert"])
        texturePopup.addItems(withTitles: ["Low", "Medium", "High", "Very High"])
        filteringPopup.addItems(withTitles: ["Bilinear", "Trilinear", "Anisotropic 2×", "Anisotropic 4×", "Anisotropic 8×", "Anisotropic 16×"])
        antialiasingPopup.addItems(withTitles: ["Off", "2× MSAA", "4× MSAA"])
        shadowsPopup.addItems(withTitles: ["Off", "Low", "Medium", "High"])
        shadersPopup.addItems(withTitles: ["Low", "High"])

        let displayWidth = Int(CGDisplayPixelsWide(CGMainDisplayID()))
        let displayHeight = Int(CGDisplayPixelsHigh(CGMainDisplayID()))
        let presets = [
            Resolution(width: 1024, height: 768),
            Resolution(width: 1280, height: 720),
            Resolution(width: 1280, height: 800),
            Resolution(width: 1440, height: 900),
            Resolution(width: 1600, height: 900),
            Resolution(width: 1920, height: 1080),
            Resolution(width: 2560, height: 1440),
        ]
        resolutions = presets.filter { $0.width <= displayWidth && $0.height <= displayHeight }
        let current = Resolution(width: displayWidth, height: displayHeight)
        if !resolutions.contains(where: { $0.key == current.key }) {
            resolutions.append(current)
        }
        if resolutions.isEmpty {
            resolutions = [current]
        }
        resolutionPopup.addItems(withTitles: resolutions.map(\.title))
    }

    private func restoreSettings() {
        mapPopup.selectItem(withTitle: defaults.string(forKey: "map") ?? "de_dust2")
        if mapPopup.selectedItem == nil { mapPopup.selectItem(at: 0) }

        let botCount = defaults.object(forKey: "botCount") == nil ? 8 : defaults.integer(forKey: "botCount")
        botCountPopup.selectItem(at: min(max(botCount, 0), 20))
        let difficulty = defaults.object(forKey: "difficulty") == nil ? 1 : defaults.integer(forKey: "difficulty")
        difficultyPopup.selectItem(at: min(max(difficulty, 0), 3))

        let resolutionKey = defaults.string(forKey: "resolution") ?? "1280x720"
        let resolutionIndex = resolutions.firstIndex(where: { $0.key == resolutionKey }) ?? 0
        resolutionPopup.selectItem(at: resolutionIndex)
        fullscreenCheckbox.state = defaults.bool(forKey: "fullscreen") ? .on : .off
        texturePopup.selectItem(at: storedInteger("textureDetail", defaultValue: 2, range: 0...3))
        filteringPopup.selectItem(at: storedInteger("textureFiltering", defaultValue: 1, range: 0...5))
        antialiasingPopup.selectItem(at: storedInteger("antialiasing", defaultValue: 0, range: 0...2))
        shadowsPopup.selectItem(at: storedInteger("shadows", defaultValue: 1, range: 0...3))
        shadersPopup.selectItem(at: storedInteger("shaderDetail", defaultValue: 1, range: 0...1))
        vsyncCheckbox.state = defaults.bool(forKey: "vsync") ? .on : .off

        sizeSlider.integerValue = storedInteger("size", defaultValue: 5, range: 1...20)
        gapSlider.integerValue = storedInteger("gap", defaultValue: 1, range: 0...15)
        thicknessSlider.integerValue = storedInteger("thickness", defaultValue: 1, range: 1...6)
        opacitySlider.integerValue = storedInteger("opacity", defaultValue: 100, range: 20...100)
        dotCheckbox.state = defaults.bool(forKey: "dot") ? .on : .off
        outlineCheckbox.state = defaults.object(forKey: "outline") == nil || defaults.bool(forKey: "outline") ? .on : .off

        let red = storedInteger("red", defaultValue: 255, range: 0...255)
        let green = storedInteger("green", defaultValue: 255, range: 0...255)
        let blue = storedInteger("blue", defaultValue: 255, range: 0...255)
        colorWell.color = NSColor(calibratedRed: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }

    private func storedInteger(_ key: String, defaultValue: Int, range: ClosedRange<Int>) -> Int {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return min(max(defaults.integer(forKey: key), range.lowerBound), range.upperBound)
    }

    private func buildWindow() {
        for control in [mapPopup, botCountPopup, difficultyPopup, resolutionPopup, colorWell] {
            control.widthAnchor.constraint(equalToConstant: 359).isActive = true
        }
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 550, height: 750),
                          styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "CS:GO Mac Launcher"
        window.center()

        let content = NSView()
        window.contentView = content
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
        ])

        stack.addArrangedSubview(sectionLabel("Match"))
        stack.addArrangedSubview(row("Map", control: mapPopup))
        stack.addArrangedSubview(row("Bots", control: botCountPopup))
        stack.addArrangedSubview(row("Bot difficulty", control: difficultyPopup))
        stack.addArrangedSubview(row("Resolution", control: resolutionPopup))
        stack.addArrangedSubview(row("Display", control: fullscreenCheckbox))
        graphicsButton.target = self
        graphicsButton.action = #selector(showGraphicsSettings)
        stack.addArrangedSubview(row("Graphics", control: graphicsButton))

        stack.addArrangedSubview(sectionLabel("Crosshair"))
        stack.addArrangedSubview(row("Color", control: colorWell))
        stack.addArrangedSubview(row("Size", control: sliderControl(sizeSlider, valueLabel: sizeValue)))
        stack.addArrangedSubview(row("Gap", control: sliderControl(gapSlider, valueLabel: gapValue)))
        stack.addArrangedSubview(row("Thickness", control: sliderControl(thicknessSlider, valueLabel: thicknessValue)))
        stack.addArrangedSubview(row("Opacity", control: sliderControl(opacitySlider, valueLabel: opacityValue)))
        stack.addArrangedSubview(row("Dot", control: dotCheckbox))
        stack.addArrangedSubview(row("Outline", control: outlineCheckbox))

        preview.translatesAutoresizingMaskIntoConstraints = false
        preview.widthAnchor.constraint(equalToConstant: 502).isActive = true
        preview.heightAnchor.constraint(equalToConstant: 90).isActive = true
        stack.addArrangedSubview(preview)

        launchButton.bezelStyle = .rounded
        launchButton.keyEquivalent = "\r"
        launchButton.target = self
        launchButton.action = #selector(launchGame)
        stack.addArrangedSubview(launchButton)
        statusLabel.textColor = .secondaryLabelColor
        stack.addArrangedSubview(statusLabel)

        for control in [mapPopup, botCountPopup, difficultyPopup, resolutionPopup, fullscreenCheckbox,
                        colorWell, sizeSlider, gapSlider, thicknessSlider, opacitySlider, dotCheckbox, outlineCheckbox] {
            control.target = self
            control.action = #selector(settingsChanged)
        }
    }

    private func sectionLabel(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.boldSystemFont(ofSize: 15)
        return label
    }

    private func row(_ title: String, control: NSView) -> NSStackView {
        let label = NSTextField(labelWithString: title)
        label.alignment = .right
        label.widthAnchor.constraint(equalToConstant: 105).isActive = true
        let row = NSStackView(views: [label, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 14
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 28).isActive = true
        return row
    }

    private func sliderControl(_ slider: NSSlider, valueLabel: NSTextField) -> NSStackView {
        slider.widthAnchor.constraint(equalToConstant: 305).isActive = true
        valueLabel.widthAnchor.constraint(equalToConstant: 46).isActive = true
        let control = NSStackView(views: [slider, valueLabel])
        control.orientation = .horizontal
        control.alignment = .centerY
        control.spacing = 8
        return control
    }

    @objc private func showGraphicsSettings() {
        if let graphicsWindow {
            graphicsWindow.makeKeyAndOrderFront(nil)
            return
        }

        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
                            styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
        panel.title = "Graphics Settings"
        panel.isFloatingPanel = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.center()
        let content = NSView()
        panel.contentView = content
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -22),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
        ])

        for control in [texturePopup, filteringPopup, antialiasingPopup, shadowsPopup, shadersPopup] {
            control.widthAnchor.constraint(equalToConstant: 280).isActive = true
            control.target = self
            control.action = #selector(settingsChanged)
        }
        stack.addArrangedSubview(row("Textures", control: texturePopup))
        stack.addArrangedSubview(row("Filtering", control: filteringPopup))
        stack.addArrangedSubview(row("Anti-aliasing", control: antialiasingPopup))
        stack.addArrangedSubview(row("Shadows", control: shadowsPopup))
        stack.addArrangedSubview(row("Shaders", control: shadersPopup))
        vsyncCheckbox.target = self
        vsyncCheckbox.action = #selector(settingsChanged)
        stack.addArrangedSubview(row("VSync", control: vsyncCheckbox))
        let note = NSTextField(labelWithString: "Changes apply the next time you launch the game.")
        note.textColor = .secondaryLabelColor
        stack.addArrangedSubview(note)
        graphicsWindow = panel
        panel.makeKeyAndOrderFront(nil)
    }

    @objc private func settingsChanged() {
        refreshPreview()
        saveSettings()
    }

    private func refreshPreview() {
        sizeValue.stringValue = "\(sizeSlider.integerValue)"
        gapValue.stringValue = "\(gapSlider.integerValue)"
        thicknessValue.stringValue = "\(thicknessSlider.integerValue)"
        opacityValue.stringValue = "\(opacitySlider.integerValue)%"
        preview.crosshairColor = colorWell.color.usingColorSpace(.deviceRGB) ?? .white
        preview.barSize = sizeSlider.integerValue
        preview.gap = gapSlider.integerValue
        preview.thickness = thicknessSlider.integerValue
        preview.opacity = opacitySlider.integerValue
        preview.showsDot = dotCheckbox.state == .on
        preview.showsOutline = outlineCheckbox.state == .on
    }

    private func saveSettings() {
        defaults.set(mapPopup.titleOfSelectedItem, forKey: "map")
        defaults.set(botCountPopup.indexOfSelectedItem, forKey: "botCount")
        defaults.set(difficultyPopup.indexOfSelectedItem, forKey: "difficulty")
        defaults.set(resolutions[resolutionPopup.indexOfSelectedItem].key, forKey: "resolution")
        defaults.set(fullscreenCheckbox.state == .on, forKey: "fullscreen")
        defaults.set(texturePopup.indexOfSelectedItem, forKey: "textureDetail")
        defaults.set(filteringPopup.indexOfSelectedItem, forKey: "textureFiltering")
        defaults.set(antialiasingPopup.indexOfSelectedItem, forKey: "antialiasing")
        defaults.set(shadowsPopup.indexOfSelectedItem, forKey: "shadows")
        defaults.set(shadersPopup.indexOfSelectedItem, forKey: "shaderDetail")
        defaults.set(vsyncCheckbox.state == .on, forKey: "vsync")
        defaults.set(sizeSlider.integerValue, forKey: "size")
        defaults.set(gapSlider.integerValue, forKey: "gap")
        defaults.set(thicknessSlider.integerValue, forKey: "thickness")
        defaults.set(opacitySlider.integerValue, forKey: "opacity")
        defaults.set(dotCheckbox.state == .on, forKey: "dot")
        defaults.set(outlineCheckbox.state == .on, forKey: "outline")
        let color = colorWell.color.usingColorSpace(.deviceRGB) ?? .white
        defaults.set(Int((color.redComponent * 255).rounded()), forKey: "red")
        defaults.set(Int((color.greenComponent * 255).rounded()), forKey: "green")
        defaults.set(Int((color.blueComponent * 255).rounded()), forKey: "blue")
    }

    @objc private func launchGame() {
        guard gameProcess == nil else { return }
        guard let map = mapPopup.titleOfSelectedItem,
              FileManager.default.fileExists(atPath: gameRoot.appendingPathComponent("csgo/maps/\(map).bsp").path) else {
            showError("Select an installed map.")
            return
        }
        let game = gameRoot.appendingPathComponent("csgo_osx64")
        guard FileManager.default.isExecutableFile(atPath: game.path) else {
            showError("The game executable is missing from \(gameRoot.path).")
            return
        }

        saveSettings()
        let color = colorWell.color.usingColorSpace(.deviceRGB) ?? .white
        let red = Int((color.redComponent * 255).rounded())
        let green = Int((color.greenComponent * 255).rounded())
        let blue = Int((color.blueComponent * 255).rounded())
        let alpha = Int((Double(opacitySlider.integerValue) * 255 / 100).rounded())
        let texturePicmip = [2, 1, 0, -1][texturePopup.indexOfSelectedItem]
        let filtering = filteringPopup.indexOfSelectedItem
        let anisotropy = [1, 1, 2, 4, 8, 16][filtering]
        let antialiasing = [0, 2, 4][antialiasingPopup.indexOfSelectedItem]
        let shadows = shadowsPopup.indexOfSelectedItem
        let vsync = vsyncCheckbox.state == .on ? 1 : 0
        let config = """
        // Generated by CS:GO Mac Launcher. Recreated each time the game starts.
        bot_quota_mode normal
        bot_quota \(botCountPopup.indexOfSelectedItem)
        bot_difficulty \(difficultyPopup.indexOfSelectedItem)
        sv_auto_adjust_bot_difficulty 0
        cl_crosshairsize \(sizeSlider.integerValue)
        cl_crosshairgap \(gapSlider.integerValue)
        cl_crosshairthickness \(thicknessSlider.integerValue)
        cl_crosshairdot \(dotCheckbox.state == .on ? 1 : 0)
        cl_crosshair_drawoutline \(outlineCheckbox.state == .on ? 1 : 0)
        cg_crosshair_r \(red)
        cg_crosshair_g \(green)
        cg_crosshair_b \(blue)
        cg_crosshair_alpha \(alpha)
        mat_picmip \(texturePicmip)
        mat_trilinear \(filtering == 1 ? 1 : 0)
        mat_forceaniso \(anisotropy)
        mat_antialias \(antialiasing)
        mat_aaquality 0
        r_shadows \(shadows == 0 ? 0 : 1)
        r_shadowrendertotexture \(shadows >= 2 ? 1 : 0)
        r_flashlightdepthtexture \(shadows >= 3 ? 1 : 0)
        mat_reducefillrate \(shadersPopup.indexOfSelectedItem == 0 ? 1 : 0)
        mat_vsync \(vsync)

        """
        let configURL = gameRoot.appendingPathComponent("csgo/cfg/mac_launcher.cfg")

        do {
            try config.write(to: configURL, atomically: true, encoding: .utf8)
            let logURL = gameRoot.appendingPathComponent("launcher-game.log")
            try Data().write(to: logURL, options: .atomic)
            let logHandle = try FileHandle(forWritingTo: logURL)
            let resolution = resolutions[resolutionPopup.indexOfSelectedItem]
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/arch")
            process.currentDirectoryURL = gameRoot
            process.standardOutput = logHandle
            process.standardError = logHandle
            process.arguments = ["-arm64", game.path, "-insecure", "-novid",
                                 fullscreenCheckbox.state == .on ? "-fullscreen" : "-windowed",
                                 "-w", "\(resolution.width)", "-h", "\(resolution.height)",
                                 "-mat_antialias", "\(antialiasing)", "-mat_aaquality", "0",
                                 "-mat_vsync", "\(vsync)",
                                 "+map", map, "+exec", "mac_launcher.cfg"]
            process.terminationHandler = { [weak self] finished in
                try? logHandle.close()
                DispatchQueue.main.async {
                    self?.gameProcess = nil
                    self?.launchButton.isEnabled = true
                    if finished.terminationReason == .uncaughtSignal {
                        self?.statusLabel.stringValue = "Game crashed (signal \(finished.terminationStatus)); see DiagnosticReports."
                    } else if finished.terminationStatus == 0 {
                        self?.statusLabel.stringValue = "Game closed."
                    } else {
                        self?.statusLabel.stringValue = "Game exited (status \(finished.terminationStatus)); see launcher-game.log."
                    }
                    NSApp.unhide(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            try process.run()
            gameProcess = process
            launchButton.isEnabled = false
            statusLabel.stringValue = "Game running on \(map)."
            graphicsWindow?.orderOut(nil)
            NSApp.hide(nil)
        } catch {
            showError("Could not launch the game: \(error.localizedDescription)")
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "CS:GO Launcher"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}
