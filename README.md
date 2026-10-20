# CodeSpot

Spotlight-style HTTP status code lookup for macOS. Native, offline, about 20 MB of memory, no dependencies.

Press **⌃⌥Space**, type a code (`404`) or words (`not found`, `server error`). Results update as you type
and the panel shrinks to fit them. Leave the field empty to list every code.

| Key | Action |
| --- | --- |
| ↑ / ↓ | Select |
| ↩ | Copy "404 Not Found" |
| ⌘↩ (hold ⌘ to see MDN mode) | Open the code's MDN page in your browser |
| ⌘, | Settings |
| Esc | Close |

## Install

Download `CodeSpot.dmg` from the GitHub release (or the build's artifact), open it and drag CodeSpot to Applications.
The app is ad-hoc signed, not notarized, so the first launch needs right-click › Open
(or `xattr -dr com.apple.quarantine /Applications/CodeSpot.app`).

## Settings

Menu bar icon › **Settings…** (or ⌘, in the panel):

- **Shortcut** – click, then press the new combo (must include ⌘, ⌃ or ⌥).
- **Launch at login**
- **Show icon in menu bar** – when hidden, ⌘, in the panel still opens Settings.

## Build

Needs only the Xcode Command Line Tools.

    ./build.sh                 # -> CodeSpot.app  (UNIVERSAL=1 for arm64 + x86_64)
    ./make-dmg.sh              # -> CodeSpot.dmg
    swift tools/make-icon.swift  # regenerate Resources/AppIcon.icns

GitHub Actions (`.github/workflows/build.yml`) builds a universal DMG on every push and PR and uploads it as an
artifact. Pushing a `v*` tag (e.g. `git tag v1.0 && git push --tags`) also publishes it as a GitHub release.

## Tests

    .build/release/CodeSpot --selftest                         # search logic checks
    .build/release/CodeSpot --snapshot "404" out.png [--cmd]   # render the results view to a PNG

## Data

Codes and descriptions come from [albert-httpstatus](https://github.com/Mujtaba1i/albert-httpstatus) and live in `Sources/CodeSpot/HTTPCodes.swift`.
