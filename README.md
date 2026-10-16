# HeliPort
![image](AppIcon-128.png)

Intel WiFi Client for (https://github.com/jzrodriguez98/itlwm)

## Download

### Latest Stable Version

[![Download from https://github.com/bigj42/HeliPort/releases/latest](https://img.shields.io/github/v/release/bigj42/HeliPort?color=%2300AABB&label=Download)](https://github.com/bigj42/HeliPort/releases/latest)

### Latest Alpha Version

[![Download from https://github.com/bigj42/HeliPort/releases](https://img.shields.io/github/v/release/bigj42/HeliPort?include_prereleases&label=Download)](https://github.com/bigj42/HeliPort/releases)

## Status

HeliPort has been upgraded, providing a state-of-the-art premium experience for Intel-based Macs. The app requires **macOS 13.0 (Ventura)** or newer and features a completely redesigned, high-fidelity user interface.

### New Features
- **📊 Advanced Telemetry**: Real-time signal strength history with high-frequency sampling (30 data points) and smoothed interpolation.
- **🔧 Technical Deep-Dive**: The dashboard now always displays critical technical metrics including PHY Mode, Channel/Bandwidth, BSSID, and Noise levels.
- **⚡️ Performance Optimized**: Rewritten UI components using modern SwiftUI patterns for minimal CPU impact while providing rich animations.
- **🪄 macOS Native**: Seamlessly integrated with the macOS menu bar, supporting all accessibility features and system-wide themes.

### 🏁 Development Status

- [x] Redesigned Dashboard
- [x] Implement always-available technical telemetry (Noise, PHY, Channel)
- [x] Enhance Signal Strength Charting (30 data points)
- [x] Optimized Intel-only (x86_64) Architecture
- [ ] Apple Silicon Support (because why not) - coming soon


Visit [Projects](https://github.com/OpenIntelWireless/HeliPort/projects) for more information.

## Building locally (code signing)

Local builds are signed with a self-signed certificate called **HeliPort Local Dev** so that
every build carries the same code identity. macOS only lets code with the same identity read the
keychain items it wrote itself, and an ad-hoc signature (`CODE_SIGN_IDENTITY=-`) is a different
identity after every rebuild — saved Wi-Fi passwords then become unreadable and the app starts
asking for them again.

The certificate lives in your login keychain, and the project uses it directly
(`CODE_SIGN_IDENTITY = "HeliPort Local Dev"`, `CODE_SIGN_STYLE = Manual`, no development team).
To recreate it on another Mac:

```sh
openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 3650 \
  -subj "/CN=HeliPort Local Dev/OU=HeliPort/O=HeliPort Local Development" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning" \
  -addext "basicConstraints=critical,CA:false" \
  -keyout heliPort-key.pem -out heliPort-cert.pem
openssl pkcs12 -export -out heliPort.p12 -inkey heliPort-key.pem -in heliPort-cert.pem \
  -name "HeliPort Local Dev" -passout pass:password
security import heliPort.p12 -k ~/Library/Keychains/login.keychain-db -P password -T /usr/bin/codesign
security add-trusted-cert -r trustRoot -p codeSign -k ~/Library/Keychains/login.keychain-db heliPort-cert.pem
```

`ENABLE_HARDENED_RUNTIME` is `NO` for local builds: library validation needs a Team ID, which a
self-signed certificate does not have, so embedded binaries (the debug dylib, Sparkle) cannot be
loaded with the hardened runtime enabled. Turn it back on when builds are signed with an Apple
Development or Developer ID identity.

CI is unaffected: it passes `CODE_SIGN_IDENTITY="-"` on the `xcodebuild` command line, which
overrides the project setting.

## Issues

Issues for this project are for bug tracking only, please carefully fill in all the blanks in the correct Issue Template.

The following types of "Issues" will be considered as invalid and will be closed and locked immediately:

- Personal help request
- Duplicated issues
- Urging updates
- Spam
- Non-English content
- Easy "Googleable" questions
  > How to build etc.
- Off-topic discussion
  > Including mentioning and distributing closed-source, non-official Intel Wi-Fi Projects.

## Contributing

We desperately need contributors to help us improve this project, any help will be highly appreciated.

- User interface and password management is implemented with `Swift 5`
- Communication with [itlwm](https://github.com/OpenIntelWireless/itlwm) is implemented with `C`

## Credits

- [@1Revenger1](https://github.com/1Revenger1) for Keychain password management improvements
- [@Bat.bat](https://github.com/williambj1) for repository management and Sparkle integration
- [@diepeterpan](https://github.com/diepeterpan) for fixing UI artifacts on macOS Sonoma and performance optimizations
- [@DogAndPot](https://github.com/DogAndPot) for initial UI implementation
- [@ErrorErrorError](https://github.com/ErrorErrorError) for UI improvement, Preference Window implementation and more
- [@Goshin](https://github.com/Goshin) for API implementation, Status Menu improvements and more
- [@igorkulman](https://github.com/igorkulman) for code refactoring, password management and more
- [@zxystd](https://github.com/zxystd) for writing [itlwm](https://github.com/OpenIntelWireless/itlwm) and APIs
- [Everyone](https://github.com/OpenIntelWireless/HeliPort/pulls?q=is%3Apr+label%3Adocumentation+is%3Aclosed) who contributed to localization files
- Primary UI icons use Apple's **SF Symbols** (Native macOS 13+ interface)
- Legacy WiFi icons are from <https://icons8.com/> (No longer used by default)
- Modern WiFi icons are from <https://github.com/framework7io/framework7-icons> (MIT License) (No longer used by default)
