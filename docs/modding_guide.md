# Modding Guide for Innova Launcher

## Introduction

The Innova Launcher supports modding capabilities for installed games. This guide will help you create, install, and manage mods for your games.

## What are Mods?

Mods (short for modifications) are alterations to a game that change its appearance, functionality, or behavior. In the Innova Launcher, mods work by replacing specific files in the game's directory with modified versions.

## Using Mods

### Installing Mods

1. Navigate to the "Library" tab in the Innova Launcher
2. Select a game from your installed games
3. Click on the game to open the game details view
4. If mods are available for the game, you'll see them listed in the "Available Mods" section
5. Click the "Install Mod" button next to the mod you want to install

### Enabling/Disabling Mods

Installed mods can be toggled on or off without uninstalling them:

1. Go to the game details view
2. Use the toggle switch next to each installed mod to enable or disable it
3. When enabled, the mod's changes will be applied when you launch the game
4. When disabled, the game will run with the original files

### Playing with Mods

1. Make sure your desired mods are enabled
2. Click the "Play with Mods" button in the game details view
3. The launcher will apply the enabled mods and launch the game

## Creating Mods

### Structure

Mods for the Innova Launcher follow a specific file structure:

```
mod_name.zip
├── src/                 # Contains modified source files
│   ├── main.py          # Modified main game file
│   ├── game_logic.py    # Other modified files
│   └── ...
├── test/                # Contains modified test files (optional)
│   ├── test_game.py     # Modified test files
│   └── ...
├── requirements.txt     # Additional dependencies (optional)
└── mod.json             # Metadata about the mod
```

### Mod Metadata

Each mod must include a `mod.json` file with the following format:

```json
{
  "id": "unique_mod_id",
  "name": "User-Friendly Mod Name",
  "version": "1.0.0",
  "author": "Your Name",
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

### Creating Your First Mod

1. Start by playing the original game to understand how it works
2. Make a copy of the game's source files (typically found in the game's `src` directory)
3. Modify these files to add your desired features or changes
4. Create the `mod.json` file with appropriate metadata
5. Add any additional requirements to a `requirements.txt` file if needed
6. Package everything into a zip file with the structure shown above

### Testing Your Mod

Before distributing your mod:

1. Install it on your own system using the Innova Launcher
2. Make sure it works correctly with the game
3. Check for any compatibility issues with other mods
4. Verify that the game can still run properly when your mod is disabled

## Best Practices

1. **Keep changes minimal**: Modify only the files you need to change
2. **Document your changes**: Include comments in your code explaining what you changed
3. **Version compatibility**: Specify which versions of the game your mod works with
4. **Backup original files**: The launcher will do this automatically, but it's good practice
5. **Consider compatibility**: Design your mod to work alongside other popular mods if possible

## Sharing Your Mods

To share your mod with others:

1. Host your mod zip file on a platform like GitHub or a mod-sharing website
2. Share the download URL with the community
3. Consider creating a readme or instructions for users

## Advanced Techniques

### Working with Requirements

If your mod requires additional Python packages:

1. List them in a `requirements.txt` file in the root of your mod zip
2. Specify exact versions to avoid compatibility issues
3. Test that the requirements install correctly

### Multiple File Modifications

When modifying multiple files:

1. Make sure to list all modified files in the `files_to_replace` section of `mod.json`
2. Keep the original file structure (e.g., if you modify `src/main.py`, keep it as `src/main.py` in your mod)
3. Consider how your changes might interact with other parts of the codebase

## Troubleshooting

If you encounter issues with your mod:

1. Check the logs in the Innova Launcher for any error messages
2. Verify that your mod works with the specific version of the game
3. Try disabling other mods to check for conflicts
4. Ensure all required dependencies are installed correctly 