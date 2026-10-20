# CodeSpot

Spotlight-style HTTP status code lookup for macOS. Native, offline, about 20 MB of memory, no dependencies.

Press **⌃⌥Space**, type a code (`404`) or words (`not found`, `server error`). Results update as you type.
↑/↓ select, ↩ copies "404 Not Found" to the clipboard, Esc closes.
Leave the field empty to list every code.

## Build

Needs only the Xcode Command Line Tools.

    ./build.sh                 # -> CodeSpot.app
    open CodeSpot.app          # menu bar icon appears; open it again to show the panel

Copy `CodeSpot.app` to `/Applications` and add it under System Settings › General › Login Items to start it at login.

## Shortcut

Menu bar icon › **Change Shortcut…**, then press the new combo (it must include ⌘, ⌃ or ⌥).

## Tests

    .build/release/CodeSpot --selftest                  # search logic checks
    .build/release/CodeSpot --snapshot "404" out.png    # render the results view to a PNG

## Data

Codes and descriptions come from [albert-httpstatus](https://github.com/Mujtaba1i/albert-httpstatus) and live in `Sources/CodeSpot/HTTPCodes.swift`.
