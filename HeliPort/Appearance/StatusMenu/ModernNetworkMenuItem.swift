import SwiftUI

struct NetworkItemView: View {
    let ssid: String
    let signalStrength: Int
    let isConnected: Bool
    let isSecure: Bool
    var onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: HeliPortUI.Spacing.medium) {
            // Signal Strength Icon
            ZStack {
                Circle()
                    .fill(isConnected ? Color.accentColor : Color.primary.opacity(0.1))
                    .frame(width: 28, height: 28)

                Image(systemName: signalIconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isConnected ? .white : .primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(ssid)
                    .font(.system(size: 13, weight: isConnected ? .bold : .semibold, design: .rounded))
                    .foregroundColor(.primary)

                if isConnected {
                    Text("Connected")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.accentColor)
                }
            }

            Spacer()

            if isSecure {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .modernMenuItem()
        .background(isHovered ? Color.primary.opacity(0.08) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            Button("Forget Network") {
                CredentialsManager.instance.remove(NetworkInfo(ssid: ssid))
            }
            Button("Copy SSID") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(ssid, forType: .string)
            }
        }
    }

    private var signalIconName: String {
        if signalStrength > -50 { return "wifi" }
        if signalStrength > -70 { return "wifi" }
        if signalStrength > -90 { return "wifi" }
        return "wifi.exclamationmark"
    }
}

// Helper for hosting in NSMenu
class ModernNetworkMenuItem: NSMenuItem {

    /// The network this row currently represents.
    ///
    /// `StatusMenuBase` reuses rows between scans, so a row can be showing a
    /// different network than the one it was created for. The click handler has
    /// to read this property at click time; capturing a `NetworkInfo` when the
    /// row is built makes a reused row connect to the wrong network.
    private(set) var networkInfo: NetworkInfo
    private var isConnected: Bool
    private var onSelect: (NetworkInfo) -> Void

    init(networkInfo: NetworkInfo, isConnected: Bool = false, onSelect: @escaping (NetworkInfo) -> Void) {
        self.networkInfo = networkInfo
        self.isConnected = isConnected
        self.onSelect = onSelect

        super.init(title: networkInfo.ssid, action: #selector(itemAction), keyEquivalent: "")
        self.target = self

        self.view = NSHostingView(rootView: makeView())
        // Adjust frame to fit menu
        self.view?.frame = NSRect(x: 0, y: 0, width: HeliPortUI.Dashboard.width, height: 40)
    }

    private func makeView() -> NetworkItemView {
        NetworkItemView(
            ssid: networkInfo.ssid,
            signalStrength: Int(networkInfo.rssi),
            isConnected: isConnected,
            isSecure: networkInfo.auth.security != ITL80211_SECURITY_NONE,
            onSelect: { [weak self] in
                guard let self = self, self.isEnabled else { return }
                self.onSelect(self.networkInfo)
            }
        )
    }

    @objc private func itemAction() {
        guard isEnabled else { return }
        onSelect(networkInfo)
    }

    func update(with info: NetworkInfo, isConnected: Bool = false) {
        self.networkInfo = info
        self.isConnected = isConnected
        self.title = info.ssid
        (self.view as? NSHostingView<NetworkItemView>)?.rootView = makeView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
