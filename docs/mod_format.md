# Mod Format Specification

Mods for Innova Launcher games follow a specific structure to ensure proper installation and compatibility.

## Overview

A mod is a zip file that contains modified versions of files from the original game, primarily replacing files in the `src` and `test` directories. Mods can also include additional requirements that will be installed alongside the mod.

## File Structure

A typical mod zip file should have the following structure:

```
mod_name.zip
├── src/                 # Contains modified source files (will replace originals)
│   ├── main.py          # Modified main game file
│   ├── game_logic.py    # Other modified files
│   └── ...
├── test/                # Contains modified test files (optional)
│   ├── test_game.py     # Modified test files
│   └── ...
├── requirements.txt     # Additional dependencies (optional)
└── mod.json             # Metadata about the mod
```

## Mod Metadata (mod.json)

Each mod must include a `mod.json` file with the following format:

```json
{
  "id": "unique_mod_id",
  "name": "User-Friendly Mod Name",
  "version": "1.0.0",
  "author": "Mod Creator",
  "description": "A detailed description of what the mod does",
  "game_id": "target_game_id",
  "min_game_version": "1.0.0",
  "max_game_version": "1.5.0",
  "files_to_replace": [
    "src/main.py",
    "src/game_logic.py",
    "test/test_game.py"
  ],
  "install_notes": "Any special notes about installation"
}
```

## Installation Process

When a mod is installed, the Innova Launcher will:

1. Extract the mod files to a temporary directory
2. Install any additional requirements specified in `requirements.txt`
3. Replace the original game files with the modified ones as specified in `files_to_replace`
4. Store metadata about the installed mod

## Enabling and Disabling Mods

Mods can be enabled or disabled through the Innova Launcher interface. When a mod is:

- **Enabled**: The modified files are used when the game is launched
- **Disabled**: The original game files are restored

## Compatibility

Mods should specify the compatible game versions in the `min_game_version` and `max_game_version` fields. The Innova Launcher will check these values to ensure compatibility before installation.

## Multiple Mods

Multiple mods can be installed for a single game, but they may conflict if they modify the same files. The Innova Launcher will warn users about potential conflicts. 