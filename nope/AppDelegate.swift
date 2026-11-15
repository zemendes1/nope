//
//  AppDelegate.swift
//  nope
//
//  Created by Tom Taylor on 04/01/2017.
//  Copyright © 2017 Twisted Digital Ltd. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let defaults = UserDefaults.standard

    // Every app nope stops from launching, grouped by what it gets replaced with.
    let categories = [ReplacementCategory.music, ReplacementCategory.games]

    var blockedApps: Set<String> {
        Set(categories.flatMap { $0.blockedApps })
    }

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    @IBOutlet weak var statusMenu: NSMenu!

    @IBAction func hideIconClicked(_ sender: NSMenuItem) {
        defaults.set(true, forKey: "hideIcon")
        NSStatusBar.system.removeStatusItem(statusItem)
        self.appIsLaunched()
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }

    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == NSEvent.EventType.rightMouseUp ||
           (event.type == NSEvent.EventType.leftMouseUp && event.modifierFlags.contains(NSEvent.ModifierFlags.control)) {
            statusItem.menu = statusMenu
            if let menu = statusItem.menu {
                menu.popUp(positioning: menu.items.first, at: NSEvent.mouseLocation, in: nil)
            }
            statusItem.menu = nil
        } else {
            if statusItem.button?.image == NSImage(named: "StatusBarButtonImage") {
                self.appIsLaunched()
                statusItem.button?.image = NSImage(named: "StatusBarButtonImageActive")
            } else {
                statusItem.button?.image = NSImage(named: "StatusBarButtonImage")
            }
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem.button?.image = NSImage(named: "StatusBarButtonImageActive")

        statusMenu.delegate = self
        self.addReplacementMenus()

        if let button = statusItem.button {
            button.action = #selector(self.statusBarButtonClicked(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        if defaults.bool(forKey: "hideIcon") {
            NSStatusBar.system.removeStatusItem(statusItem)
        }

        self.appIsLaunched()
        self.createListener()
    }

    func createListener() {
        let workspaceNotificationCenter = NSWorkspace.shared.notificationCenter
        workspaceNotificationCenter.addObserver(self, selector: #selector(self.appWillLaunch(note:)), name: NSWorkspace.willLaunchApplicationNotification, object: nil)
    }

    func appIsLaunched() {
        let apps = NSWorkspace.shared.runningApplications
        for currentApp in apps.enumerated() {
            let runningApp = apps[currentApp.offset]

            if runningApp.activationPolicy == .regular,
               let bundleID = runningApp.bundleIdentifier,
               blockedApps.contains(bundleID) {
                runningApp.forceTerminate()
            }
        }
    }

    @objc func appWillLaunch(note:Notification) {
        if statusItem.button?.image == NSImage(named: "StatusBarButtonImageActive") || defaults.bool(forKey: "hideIcon") {
            if let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                if let bundleID = app.bundleIdentifier, blockedApps.contains(bundleID) {
                    app.forceTerminate()
                    if let category = categories.first(where: { $0.blockedApps.contains(bundleID) }) {
                        self.launchReplacement(for: category)
                    }
                }
            }
        }
    }

    func launchReplacement(for category: ReplacementCategory) {
        guard let replacement = defaults.string(forKey: category.defaultsKey) else { return }
        Replacement.open(replacement)
    }

    func terminateProcessWith(_ processId:Int,_ processName:String) {
        let process = NSRunningApplication.init(processIdentifier: pid_t(processId))
        process?.forceTerminate()
    }

}

// MARK: - Replacements

/// Something to open instead of a blocked app. `target` is stored in UserDefaults and is one of:
/// a URL ("https://…"), an app path ("/Applications/…"), or a bundle ID ("com.spotify.client").
struct Replacement {
    let name: String
    let target: String

    static func open(_ target: String) {
        let workspace = NSWorkspace.shared
        if target.hasPrefix("/") {
            workspace.openApplication(at: URL(fileURLWithPath: target), configuration: .init())
        } else if target.contains("://"), let url = URL(string: target) {
            workspace.open(url)
        } else if let appURL = workspace.urlForApplication(withBundleIdentifier: target) {
            workspace.openApplication(at: appURL, configuration: .init())
        }
    }

    /// Websites always work; apps only when installed.
    var isAvailable: Bool {
        target.contains("://") || NSWorkspace.shared.urlForApplication(withBundleIdentifier: target) != nil
    }
}

struct ReplacementCategory {
    let title: String
    let blockedApps: Set<String>
    let defaultsKey: String
    let known: [Replacement]

    static let music = ReplacementCategory(
        title: "Instead of Music, open",
        blockedApps: ["com.apple.Music", "com.apple.iTunes"],
        defaultsKey: "replacement", // same key noTunes used, so existing `defaults write` setups keep working
        known: [
            Replacement(name: "Spotify", target: "com.spotify.client"),
            Replacement(name: "TIDAL", target: "com.tidal.desktop"),
            Replacement(name: "YouTube Music (web)", target: "https://music.youtube.com/"),
            Replacement(name: "SoundCloud (web)", target: "https://soundcloud.com/"),
        ])

    static let games = ReplacementCategory(
        title: "Instead of Games, open",
        blockedApps: ["com.apple.games"],
        defaultsKey: "gamesReplacement",
        known: [
            Replacement(name: "Steam", target: "com.valvesoftware.steam"),
            Replacement(name: "Epic Games Launcher", target: "com.epicgames.EpicGamesLauncher"),
        ])
}

extension AppDelegate: NSMenuDelegate {

    private static let replacementMenuTag = 4242

    /// Inserts one submenu per category at the top of the status menu.
    func addReplacementMenus() {
        for (index, category) in categories.enumerated() {
            let item = NSMenuItem(title: category.title, action: nil, keyEquivalent: "")
            item.tag = Self.replacementMenuTag
            item.representedObject = index
            item.submenu = NSMenu(title: category.title)
            statusMenu.insertItem(item, at: index)
        }
        statusMenu.insertItem(.separator(), at: categories.count)
    }

    /// Rebuilds the submenus each time the menu opens, so checkmarks and "not installed" stay current.
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === statusMenu else { return }
        for item in statusMenu.items where item.tag == Self.replacementMenuTag {
            guard let index = item.representedObject as? Int, let submenu = item.submenu else { continue }
            fillSubmenu(submenu, for: categories[index])
        }
    }

    private func fillSubmenu(_ submenu: NSMenu, for category: ReplacementCategory) {
        submenu.removeAllItems()
        let current = defaults.string(forKey: category.defaultsKey)

        func add(_ title: String, target: String?, enabled: Bool = true) {
            let item = NSMenuItem(title: title, action: enabled ? #selector(replacementChosen(_:)) : nil, keyEquivalent: "")
            item.target = self
            item.representedObject = [category.defaultsKey, target as Any]
            item.state = (target == current) ? .on : .off
            item.isEnabled = enabled
            submenu.addItem(item)
        }

        add("Nothing", target: nil)
        submenu.addItem(.separator())
        for replacement in category.known {
            let available = replacement.isAvailable
            add(available ? replacement.name : "\(replacement.name) (not installed)", target: replacement.target, enabled: available)
        }

        // Something picked with "Choose App…" or set via `defaults write` that isn't in the list.
        if let current, !category.known.contains(where: { $0.target == current }) {
            submenu.addItem(.separator())
            add(displayName(for: current), target: current)
        }

        submenu.addItem(.separator())
        let choose = NSMenuItem(title: "Choose App…", action: #selector(chooseReplacementApp(_:)), keyEquivalent: "")
        choose.target = self
        choose.representedObject = category.defaultsKey
        submenu.addItem(choose)
    }

    private func displayName(for target: String) -> String {
        if target.hasPrefix("/") {
            return FileManager.default.displayName(atPath: target).replacingOccurrences(of: ".app", with: "")
        }
        return target
    }

    @objc func replacementChosen(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? [Any], let key = info.first as? String else { return }
        if let target = info.last as? String {
            defaults.set(target, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    @objc func chooseReplacementApp(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        let panel = NSOpenPanel()
        panel.title = "Choose a replacement app"
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        NSApp.activate(ignoringOtherApps: true) // nope has no Dock icon, so bring the panel to the front
        if panel.runModal() == .OK, let url = panel.url {
            defaults.set(url.path, forKey: key)
        }
    }
}
