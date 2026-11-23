# MacProxySwitcher

A macOS menu bar app for quickly switching system proxy profiles. Requires macOS 13 or later.

## Build a release

With Xcode installed and selected as the active developer directory, run:

```sh
./scripts/build-release.sh
```

The script builds an optimized universal app for Apple Silicon and Intel, checks its architectures, signature, and bundled icon, and packages it in `build/release/`:

- `MPS.app`
- `MPS-<version>-macOS-universal.zip`
- A SHA-256 checksum alongside the ZIP

The app uses an ad hoc signature for local use. Distribution with Developer ID signing and Apple notarization requires your signing credentials and a separate distribution step.

Open `MPS.app` to access its globe icon in the menu bar. Choose **Manage Configurations…** to edit proxy profiles.

Choose **Save current** to capture the current PAC, HTTP, HTTPS, and SOCKS settings as a new profile. The configuration window opens with the new profile selected and its name ready to edit. Profiles and edits are saved automatically. Proxy authentication credentials must be entered manually.

Run `./scripts/test-proxy-snapshot.sh` to check capture, persistence, profile selection, and error handling without changing system proxy settings.

## App icon

The editable artwork is in `artwork/AppIcon.svg`. The app icon catalog includes every macOS size from 16 to 1024 pixels, so normal builds need no additional image tools.

To regenerate the icon after editing the SVG, install `librsvg` and run:

```sh
brew install librsvg
./scripts/generate-app-icon.sh
```

`project.yml` is the XcodeGen project specification. The checked-in `MPS.xcodeproj` can be built directly without running XcodeGen.
