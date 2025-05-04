# Innova Launcher

A Flutter-based launcher for Python apps and games with automatic setup.

use the releases as this code wont build (i dont know how to use git)

## Features

- Checks for Python installation and provides installation guidance
- Automatically installs required dependencies like Pygame
- Downloads applications from a centralized repository
- Manages installed Python applications and games
- Modern, intuitive Material Design user interface
- Cross-platform (Windows, macOS, Linux)

## Installation

### Requirements
- Flutter SDK 3.7.0 or higher
- Dart SDK
- Python 3.6+ (for running the installed applications)

### Getting Started

1. Clone this repository
2. Run `flutter pub get` to fetch dependencies
3. Run `flutter run` to start the application

## Building for Distribution

Build for your target platform:

```bash
# For Windows
flutter build windows

# For macOS
flutter build macos

# For Linux
flutter build linux
```

## Usage

### Store Tab
Browse and install available Python applications and games.

### Library Tab
View, launch, and manage your installed applications.

## App Repository Format

Applications are defined in a JSON file with the following structure:

```json
{
  "App Name": {
    "description": "App description",
    "tags": ["tag1", "tag2"],
    "version": "1.0.0",
    "download_url": "https://example.com/downloads/app.zip",
    "author": "Author Name",
    "requires_pygame": true,
    "min_python_version": "3.6"
  }
}
```

## How It Works

1. The launcher checks if Python is installed and available in the system PATH
2. If Python is not installed, it guides the user to the appropriate installation website
3. It also checks for Pygame installation if required by applications
4. Applications are downloaded as ZIP files and extracted to the app directory
5. The launcher manages Python dependencies through pip
6. Applications run in their own process, separate from the launcher

## License

MIT License
