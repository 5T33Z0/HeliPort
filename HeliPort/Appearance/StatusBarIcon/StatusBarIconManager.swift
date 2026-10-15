//
//  StatusBarIconManager.swift
//  HeliPort
//
//  Created by 梁怀宇 on 2020/4/7.
//  Copyright © 2020 OpenIntelWireless. All rights reserved.
//

/*
 * This program and the accompanying materials are licensed and made available
 * under the terms and conditions of the The 3-Clause BSD License
 * which accompanies this distribution. The full text of the license may be found at
 * https://opensource.org/licenses/BSD-3-Clause
 */

import Cocoa

protocol StatusBarIconProvider {
    var transition: CATransition? { get }
    var off: NSImage { get }
    var connected: NSImage { get }
    var disconnected: NSImage { get }
    var warning: NSImage { get }
    var scanning: [NSImage] { get }
    func getRssiImage(_ RSSI: Int16) -> NSImage?
}

class StatusBarIcon {
    private static var instance: StatusBarIcon?

    private let statusBar: NSStatusItem
    private let icons: StatusBarIconProvider
    private var timer: Timer?
    private var tickIndex: Int = 0
    private var tickDirection: Int = 1

    private init(_ statusBar: NSStatusItem, _ icons: StatusBarIconProvider) {
        self.statusBar = statusBar
        self.icons = icons
    }

    static func shared(statusBar: NSStatusItem? = nil, icons: StatusBarIconProvider? = nil) -> StatusBarIcon {
        if let instance {
            return instance
        }
        guard let statusBar, let icons else {
            fatalError("Must provide statusBar and iconProvider for the first initialization.")
        }
        instance = StatusBarIcon(statusBar, icons)
        return instance!
    }

    func on() {
        setImage(icons.disconnected)
    }

    func off() {
        setImage(icons.off)
    }

    func connected() {
        setImage(icons.connected)
    }

    func disconnected() {
        setImage(icons.disconnected)
    }

    func connecting() {
        perform {
            // A connection attempt may be reported by several sources at once
            // (the connect call and the periodic state poll). Keep a single timer
            // so a later `connected()`/`signalStrength()` always cancels it.
            guard self.timer == nil else { return }
            self.tickIndex = 0
            self.tickDirection = 1
            let timer = Timer(timeInterval: 0.3, target: self, selector: #selector(self.tick),
                              userInfo: nil, repeats: true)
            // .common keeps the animation running while the menu is open.
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
            timer.fire()
        }
    }

    func warning() {
        setImage(icons.warning)
    }

    func error() {
        setImage(#imageLiteral(resourceName: "WiFiStateError"))
    }

    func signalStrength(rssi: Int16) {
        setImage(icons.getRssiImage(rssi))
    }

    func getRssiImage(rssi: Int16) -> NSImage? {
        return icons.getRssiImage(rssi)
    }

    func updateStatusText(_ text: String?) {
        perform {
            self.statusBar.button?.title = text ?? ""
            // Ensure image and text have appropriate spacing
            self.statusBar.button?.imagePosition = (text == nil || text?.isEmpty == true) ? .imageOnly : .imageLeft
        }
    }

    /// Cancels the animation and applies `image` on the main thread.
    ///
    /// Every state change is enqueued on the main queue in call order, so the
    /// animation timer can never outlive the state that started it regardless of
    /// which thread the caller is on.
    private func setImage(_ image: NSImage?) {
        perform {
            self.stopTimer()
            self.statusBar.button?.image = image
        }
    }

    @objc private func tick() {
        if let transition = self.icons.transition {
            self.statusBar.button?.layer?.add(transition, forKey: kCATransition)
        }
        self.statusBar.button?.image = self.icons.scanning[self.tickIndex]

        self.tickIndex += self.tickDirection
        if self.tickIndex == 0 || self.tickIndex == self.icons.scanning.endIndex - 1 {
            self.tickDirection *= -1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func perform(_ block: @escaping () -> Void) {
        // Always hop through the main queue, even when already on the main thread,
        // so successive state changes are applied strictly in call order.
        DispatchQueue.main.async(execute: block)
    }
}
