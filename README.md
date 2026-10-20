# CodeSpot

Spotlight-style HTTP status code lookup for macOS. Native, offline, about 20 MB of memory, no dependencies.

Press **⌃⌥Space** and a Liquid Glass search bar pops up where Spotlight does. Type a code (`404`) or words (`not found`, `server error`). Results update as you type
and the panel grows downward from the centered search bar. Type a space to list every code.

| Key | Action |
| --- | --- |
| ↑ / ↓ | Select |
| ↩ | Copy "404 Not Found" |
| ⌘↩ (hold ⌘ to see MDN mode; modifier configurable) | Open the code's MDN page in your browser (if MDN has one) |
| ⌘ + , | Settings |
| Esc | Close (it also closes itself when Spotlight opens) |

Drag the panel by its edge to move it; it opens there from then on. Menu bar › **Reset Panel Position** puts it back
where Spotlight opens by default (centered, 29% from the top).

## Install

Download `CodeSpot.dmg` from the GitHub release (or the build's artifact), open it and drag CodeSpot to Applications.
The app is ad-hoc signed, not notarized, so the first launch needs right-click › Open
(or `xattr -dr com.apple.quarantine /Applications/CodeSpot.app`).

## Settings

Menu bar icon › **Settings…** (or ⌘ + , in the panel):

- **Shortcut** – click, then press the new combo (must include ⌘, ⌃ or ⌥).
- **Open MDN with** – ⌘, ⌥, ⌃ or ⇧ + ↩.
- **Launch at login**
- **Show icon in menu bar** – when hidden, ⌘ + , in the panel still opens Settings.

## Build

Needs only the Xcode Command Line Tools.

    ./build.sh                 # -> CodeSpot.app  (UNIVERSAL=1 for arm64 + x86_64)
    ./make-dmg.sh              # -> CodeSpot.dmg
    swift tools/make-icon.swift  # regenerate Resources/AppIcon.icns

GitHub Actions (`.github/workflows/build.yml`) builds a universal DMG on every push and PR and uploads it as an
artifact. Pushing a `v*` tag (e.g. `git tag v1.0 && git push --tags`) also publishes it as a GitHub release.

## Tests

    .build/release/CodeSpot --selftest                         # search logic checks
    .build/release/CodeSpot --snapshot "404" out.png [--mdn]   # render the results view to a PNG

## Data

Codes and descriptions come from [albert-httpstatus](https://github.com/Mujtaba1i/albert-httpstatus) and live in `Sources/CodeSpot/HTTPCodes.swift`.

## Moving the project to another Mac

The whole git history lives in the hidden `.git` folder inside `CodeSpot`, so zipping the folder takes every commit with it.

1. **Zip it on this Mac** (skip the build output, it gets rebuilt):

       cd ~/Desktop/claude-test
       zip -r CodeSpot.zip CodeSpot -x "CodeSpot/.build/*" "CodeSpot/CodeSpot.app/*" "CodeSpot/CodeSpot.dmg"

   Finder › Compress also works and keeps `.git`, but includes `.build/` too (bigger zip).

2. **Unzip it on the other Mac**, then check the history came along:

       cd CodeSpot
       git log --oneline        # same commits, same hashes

3. **Commit as your personal account from now on.** This sets the author only for this repo and leaves every
   existing commit exactly as it is:

       git config user.name  "Your Name"
       git config user.email "you@personal.com"
       git config user.email    # check it prints the personal email

   Old commits keep showing the adg author. That's expected: changing them would rewrite every commit hash.

4. **Build it there.** Install the Command Line Tools once (`xcode-select --install`), then `./build.sh`.

5. **Optional: push to GitHub** so the Action builds the DMG. Create an empty private repo, then:

       git remote add origin git@github.com:<you>/CodeSpot.git
       git push -u origin main

   The existing commits' adg email is visible to anyone who can see the repo's history.

