//
//  StatusMenuSelfTest.swift
//  HeliPort
//
//  Created by HeliPort contributors.
//  Copyright © 2026 OpenIntelWireless. All rights reserved.
//

/*
 * This program and the accompanying materials are licensed and made available
 * under the terms and conditions of the The 3-Clause BSD License
 * which accompanies this distribution. The full text of the license may be found at
 * https://opensource.org/licenses/BSD-3-Clause
 */

#if DEBUG
import Cocoa

/// Regression check for the network rows of the status menu.
///
/// The menu reuses its rows between scans, so a row can end up showing a
/// different network than the one it was built for. Clicking a row has to join
/// the network the row is *showing*; this test drives the same dispatch a click
/// uses (`NSMenu.performActionForItem`) and checks which network the app asks
/// for.
///
/// It needs the simulated driver, since it never touches the real one:
///
///     HeliPort.app/Contents/MacOS/HeliPort --simulate --status-menu-self-test
///
/// Exit code 0 means every row asked to join the network it displayed.
enum StatusMenuSelfTest {

    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("--status-menu-self-test")
    }

    static func run(menu: StatusMenuModern) -> Int32 {
        guard SimulationMode.isEnabled else {
            report("FAIL: the status menu self test needs the simulated driver, launch with --simulate")
            return 1
        }

        menu.menuWillOpen(menu)
        guard wait(until: { !allRows(in: menu).isEmpty }, timeout: 15) else {
            report("FAIL: the menu never listed a network")
            return 1
        }

        var failures = [String]()

        // A real click on an open network: the row's action goes through
        // NetworkManager and the driver, so the whole click-to-driver path runs.
        // A collapsed section can hide the row, but the click it dispatches is
        // the same one a user makes on a visible row.
        if let openRow = allRows(in: menu).first(where: {
            $0.isEnabled && $0.networkInfo.auth.security == ITL80211_SECURITY_NONE
        }) {
            let expected = openRow.title
            let wasSavedBefore = CredentialsManager.instance.getSavedNetworkSSIDs().contains(expected)

            perform(openRow, in: menu)
            if wait(until: { connectedSSID() == expected }, timeout: 15) {
                report("PASS: clicking \(expected) joined \(expected)")
            } else {
                failures.append("clicking \(expected) left the station on \(connectedSSID() ?? "nothing")")
            }

            // Joining saves the network, so undo it for a simulated SSID that was
            // not saved before instead of writing junk into the user's keychain.
            if !wasSavedBefore {
                CredentialsManager.instance.remove(NetworkInfo(ssid: expected))
            }
        } else {
            report("SKIP: no open network in the scan to join without a password")
        }

        // Joining drops a network from the scan list, so the rows below it are
        // reused for other networks. Those reused rows are exactly where a click
        // used to be wired to the network the row was originally created for, so
        // check every row the user could click and then move the station on to
        // force the next scan to relabel the rows.
        var titlesBefore = titles(of: allRows(in: menu))
        var checkedRows = 0

        for _ in 0..<4 {
            let rows = allRows(in: menu).filter { $0.isEnabled }
            guard !rows.isEmpty else { break }

            for row in rows {
                let displayed = row.title
                var requested: String?
                NetworkManager.connectObserver = { requested = $0.ssid }
                perform(row, in: menu)
                NetworkManager.connectObserver = nil

                checkedRows += 1
                if requested != displayed {
                    failures.append("the row showing \(displayed) asked to join \(requested ?? "nothing")")
                }
            }

            let shift = allRows(in: menu).first(where: { $0.title != rows[0].title })?.title
            guard let shift = shift else { break }
            _ = Driver.connect(ssid: shift, password: "simulated-password")

            let settled = wait(until: { connectedSSID() == shift }, timeout: 15)
                && wait(until: { titles(of: allRows(in: menu)) != titlesBefore }, timeout: 15)
            guard settled else { break }

            titlesBefore = titles(of: allRows(in: menu))
        }

        report("Checked \(checkedRows) row clicks")
        if failures.isEmpty {
            report("PASS: every row joined the network it was showing")
            return 0
        }

        failures.forEach { report("FAIL: \($0)") }
        return 1
    }

    // MARK: - Helpers

    /// The rows of the menu in menu order, including hidden ones.
    private static func allRows(in menu: StatusMenuModern) -> [ModernNetworkMenuItem] {
        menu.items.compactMap { $0 as? ModernNetworkMenuItem }
    }

    /// Titles keyed by row, so a row that was reused for another network can be
    /// told apart from a row that merely moved.
    private static func titles(of rows: [ModernNetworkMenuItem]) -> [ObjectIdentifier: String] {
        Dictionary(uniqueKeysWithValues: rows.map { (ObjectIdentifier($0), $0.title) })
    }

    private static func perform(_ row: NSMenuItem, in menu: StatusMenuModern) {
        let index = menu.index(of: row)
        guard index != NSNotFound else {
            report("FAIL: the menu could not find \(row.title)")
            return
        }
        menu.performActionForItem(at: index)
    }

    private static func connectedSSID() -> String? {
        guard let info = Driver.stationInfo() else { return nil }
        let ssid = String(ssid: info.ssid)
        return ssid.isEmpty ? nil : ssid
    }

    /// Pumps the main run loop so the menu's asynchronous scans, connections and
    /// timers can make progress while the test waits for them.
    @discardableResult
    private static func wait(until condition: () -> Bool, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }
        return condition()
    }

    private static func report(_ message: String) {
        print("[status-menu] \(message)")
        Log.debug("Status menu self test: \(message)")
        FileHandle.standardOutput.synchronizeFile()
    }
}
#endif
