# Project guide

BossTensionDisplay is a UE4SS Lua mod for Phantom Blade Zero. It reads combat tension and creates its own UMG HUD. The runtime does not change combat properties, AI or saves.

## Files

- `BossTensionDisplay/Scripts/main.lua`: update scheduling, F3/F4 bindings, runtime shutdown and reload.
- `Reader.lua`: safe reflection helpers, active boss discovery, readouts and recent outcome/base-weight reads.
- `HUD.lua`: UMG construction, object lifetime validation and display updates.
- `Settings.lua`: user-editable keys, layout and polling options.
- `Probe.lua`: optional read-only reflection diagnostics.
- `enabled.txt`: UE4SS enable marker.

The game-specific UE4SS prerequisite is external. No package manager, compiler, environment secret or shell bootstrap is required. Lua modules depend on UE4SS globals and cannot be executed as a standalone application.

## Package

From the repository root, with PowerShell 7:

```powershell
pwsh -NoProfile -File tools/Build-Release.ps1
```

This creates `dist/BossTensionDisplay-0.1.1.zip` using a fixed file whitelist and refuses to overwrite an existing archive. `-OutputDirectory <existing-or-new-directory>` chooses another directory; its parent must exist. Retain or rename an earlier output before making another package.

The archive contains the mod folder, both READMEs, LICENSE, CHANGELOG and the referenced screenshot. It excludes Git metadata, audit reports, tools and private game data. Verify archive entries and runtime file hashes before release.

## Runtime checks

Use the exact game/UE4SS versions being tested, record those versions, and check an active boss encounter, waiting state, death/re-entry, F3 visibility and F4 reload. Inspect relevant `[BossTensionDisplay]` log lines. Do not claim standalone syntax or packaging checks prove in-game compatibility.

Preserve native-address comparisons, weak-key map `Find` compatibility, widget descendant/world validation and explicit `dofile` reload behavior unless a tested change replaces them. Events expose outcome sign and profile base weight, not final contribution. Delta and confidence come from the game.

## License and publication

Use the custom [LICENSE](LICENSE) consistently. This is source-available, not MIT or OSI open source; keep the exclusion, no-sale and source-sharing terms. Do not bundle third-party game assets or prerequisite binaries. Never publish audit reports, local paths, saves, logs, dumps or credentials.
