import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';
import 'package:archive/archive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'mod_manager.dart';

/// Represents a mod for a game
class GameMod {
  final String id;
  final String name;
  final String? version;
  final String? author;
  final String? description;
  final String? downloadUrl;
  final String gameId;
  final String? minGameVersion;
  final String? maxGameVersion;
  final bool enabled;
  final String? installPath;
  final List<String>? filesReplaced;
  final List<String>? additionalRequirements;
  
  GameMod({
    required this.id,
    required this.name,
    this.version,
    this.author,
    this.description,
    this.downloadUrl,
    required this.gameId,
    this.minGameVersion,
    this.maxGameVersion,
    this.enabled = false,
    this.installPath,
    this.filesReplaced,
    this.additionalRequirements,
  });
  
  /// Create a copy of this mod with the specified fields replaced
  GameMod copyWith({
    String? id,
    String? name,
    String? version,
    String? author,
    String? description,
    String? downloadUrl,
    String? gameId,
    String? minGameVersion,
    String? maxGameVersion,
    bool? enabled,
    String? installPath,
    List<String>? filesReplaced,
    List<String>? additionalRequirements,
  }) {
    return GameMod(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      author: author ?? this.author,
      description: description ?? this.description,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      gameId: gameId ?? this.gameId,
      minGameVersion: minGameVersion ?? this.minGameVersion,
      maxGameVersion: maxGameVersion ?? this.maxGameVersion,
      enabled: enabled ?? this.enabled,
      installPath: installPath ?? this.installPath,
      filesReplaced: filesReplaced ?? this.filesReplaced,
      additionalRequirements: additionalRequirements ?? this.additionalRequirements,
    );
  }
  
  /// Create a GameMod from a JSON map
  factory GameMod.fromJson(Map<String, dynamic> json) {
    return GameMod(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String?,
      author: json['author'] as String?,
      description: json['description'] as String?,
      downloadUrl: json['download_url'] as String?,
      gameId: json['game_id'] as String,
      minGameVersion: json['min_game_version'] as String?,
      maxGameVersion: json['max_game_version'] as String?,
      enabled: json['enabled'] as bool? ?? false,
      installPath: json['install_path'] as String?,
      filesReplaced: (json['files_replaced'] as List<dynamic>?)?.map((e) => e as String).toList(),
      additionalRequirements: (json['additional_requirements'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }
  
  /// Convert this GameMod to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'author': author,
      'description': description,
      'download_url': downloadUrl,
      'game_id': gameId,
      'min_game_version': minGameVersion,
      'max_game_version': maxGameVersion,
      'enabled': enabled,
      'install_path': installPath,
      'files_replaced': filesReplaced,
      'additional_requirements': additionalRequirements,
    };
  }
}

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class AppModel extends ChangeNotifier {
  Map<String, dynamic> _apps = {};
  List<String> _installedApps = [];
  bool _isLoading = false;
  String _statusMessage = "Ready";
  double _progress = 0.0;
  bool _pythonInstalled = false;
  bool _pygameInstalled = false;
  bool _isDarkMode = true;
  bool _isInstallingPython = false;
  bool _isInstallingPygame = false;
  String _selectedCategory = 'all';
  Set<String> _selectedTags = {};
  List<String> _availableTags = [];
  
  // Game board related fields
  String? _selectedGameId;
  Map<String, List<GameMod>> _gameMods = {};
  bool _isLoadingMods = false;
  late ModManager _modManager;

  Map<String, dynamic> get apps => _apps;
  List<String> get installedApps => _installedApps;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  double get progress => _progress;
  bool get pythonInstalled => _pythonInstalled;
  bool get pygameInstalled => _pygameInstalled;
  bool get isDarkMode => _isDarkMode;
  bool get isInstallingPython => _isInstallingPython;
  bool get isInstallingPygame => _isInstallingPygame;
  String get selectedCategory => _selectedCategory;
  Set<String> get selectedTags => _selectedTags;
  List<String> get availableTags => _availableTags;
  
  // Game board related getters
  String? get selectedGameId => _selectedGameId;
  Map<String, List<GameMod>> get gameMods => _gameMods;
  bool get isLoadingMods => _isLoadingMods;
  List<GameMod> getModsForGame(String gameId) => _modManager.getModsForGame(gameId);
  bool hasModsForGame(String gameId) => _modManager.hasModsForGame(gameId);

  // Categories
  final List<Category> categories = [
    Category(id: 'all', name: 'All Apps', icon: Icons.apps, color: Colors.blue),
    Category(id: 'games', name: 'Games', icon: Icons.games, color: Colors.purple),
    Category(id: 'education', name: 'Education', icon: Icons.school, color: Colors.orange),
    Category(id: 'utilities', name: 'Utilities', icon: Icons.build, color: Colors.green),
    Category(id: 'media', name: 'Media', icon: Icons.movie, color: Colors.red),
    Category(id: 'development', name: 'Development', icon: Icons.code, color: Colors.indigo),
  ];

  // Constants
  static const String appsJsonUrl = "https://raw.githubusercontent.com/I-FOX-Development/innova-launcher-backend/refs/heads/main/index.json";
  static const String modsJsonUrl = "https://raw.githubusercontent.com/I-FOX-Development/innova-launcher-backend/refs/heads/main/mods.json";
  static const String themePrefsKey = "dark_mode_enabled";
  static const String homebrewUrl = "https://brew.sh";
  static const String windowsPythonUrl = "https://www.python.org/downloads/windows/";
  static const String linuxPythonInfo = "https://www.python.org/downloads/source/";
  static const String macOSPythonUrl = "https://www.python.org/downloads/macos/";
  static const String chocolateyUrl = "https://chocolatey.org/install";
  static const String installedAppsFile = "games_installed.json";
  static const String modsFolder = "mods";
  static const String modsFileName = "mods.json";
  
  AppModel() {
    _init();
  }

  Future<void> _init() async {
    _setLoading(true, "Initializing...");
    await _loadThemePreference();
    await _createDirectories();
    await _platformSpecificSetup();
    await _checkPythonInstallation();
    await _loadInstalledAppsData();
    await loadInstalledApps();
    await loadApps();
    _initModManager();
    _setLoading(false);
  }
  
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(themePrefsKey) ?? true;
      notifyListeners();
    } catch (e) {
      // If preferences can't be loaded, default to dark mode
      _isDarkMode = true;
    }
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(themePrefsKey, _isDarkMode);
    } catch (e) {
      // Handle error silently - theme will change for this session
    }
    notifyListeners();
  }

  void _setLoading(bool loading, [String? message]) {
    _isLoading = loading;
    if (message != null) {
      _statusMessage = message;
    }
    notifyListeners();
  }

  void _setProgress(double value) {
    _progress = value;
    notifyListeners();
  }

  Future<void> _createDirectories() async {
    final appDir = await getApplicationSupportDirectory();
    final appsDir = Directory('${appDir.path}/apps');
    if (!await appsDir.exists()) {
      await appsDir.create(recursive: true);
    }
    
    // Create games data directory
    final gamesDataDir = Directory('${appDir.path}/games_data');
    if (!await gamesDataDir.exists()) {
      await gamesDataDir.create(recursive: true);
    }
  }

  Future<void> _platformSpecificSetup() async {
    try {
      if (Platform.isWindows) {
        // On Windows, check PATH environment variable for Python
        final result = await Process.run('where', ['python']);
        if (result.exitCode != 0) {
          // Check if Python is in common installation directories
          final programFiles = Platform.environment['ProgramFiles'] ?? 'C:\\Program Files';
          final programFilesX86 = Platform.environment['ProgramFiles(x86)'] ?? 'C:\\Program Files (x86)';
          
          final possiblePaths = [
            '$programFiles\\Python311\\python.exe',
            '$programFilesX86\\Python311\\python.exe',
            '$programFiles\\Python310\\python.exe',
            '$programFilesX86\\Python310\\python.exe',
            '$programFiles\\Python39\\python.exe',
            '$programFilesX86\\Python39\\python.exe',
          ];
          
          for (final path in possiblePaths) {
            if (await File(path).exists()) {
              // Found Python, but it's not in PATH
              _setLoading(true, "Python found but not in PATH. Will try to use anyway.");
              break;
            }
          }
        }
      } else if (Platform.isMacOS) {
        // On macOS, check if Homebrew is installed for future use
        final hasHomebrew = await _checkHomebrewInstallation();
        if (!hasHomebrew) {
          _setLoading(true, "Homebrew not found. Some features may require it for installation.");
        }
        
        // Check if Xcode command line tools are installed
        try {
          final xcodeResult = await Process.run('xcode-select', ['--print-path']);
          if (xcodeResult.exitCode != 0) {
            _setLoading(true, "Xcode command line tools may not be installed. Some installers may request them.");
          }
        } catch (e) {
          // Xcode command line tools probably not installed
          _setLoading(true, "Xcode command line tools not found. Some installers may request them.");
        }
      } else if (Platform.isLinux) {
        // On Linux, check for common package managers
        bool hasApt = await _checkCommandExists('apt');
        bool hasDnf = await _checkCommandExists('dnf');
        bool hasYum = await _checkCommandExists('yum');
        bool hasPacman = await _checkCommandExists('pacman');
        
        if (!(hasApt || hasDnf || hasYum || hasPacman)) {
          _setLoading(true, "No supported package manager found. Automatic installation may be limited.");
        }
        
        // Check for sudo privileges (needed for package installation)
        try {
          final sudoResult = await Process.run('sudo', ['-n', 'true']);
          if (sudoResult.exitCode != 0) {
            _setLoading(true, "Sudo privileges may be required for some installations.");
          }
        } catch (e) {
          _setLoading(true, "Sudo access not available. Some features may be limited.");
        }
      }
    } catch (e) {
      // Silently handle initialization errors
      _setLoading(true, "Platform-specific setup completed with warnings.");
    }
  }

  Future<void> _checkPythonInstallation() async {
    _setLoading(true, "Checking Python installation...");
    
    String pythonCommand = _getPythonCommand();
    
    try {
      final result = await Process.run(pythonCommand, ['--version']);
      if (result.exitCode == 0) {
        _pythonInstalled = true;
        await _checkPygameInstallation();
        return;
      }
      
      // If primary python command failed, try alternatives
      if (Platform.isMacOS && pythonCommand != 'python') {
        // Try 'python' as fallback on macOS
        final resultFallback = await Process.run('python', ['--version']);
        if (resultFallback.exitCode == 0) {
          _pythonInstalled = true;
          await _checkPygameInstallation();
          return;
        }
      } else if (Platform.isWindows && pythonCommand != 'py') {
        // Try 'py' as fallback on Windows
        final resultFallback = await Process.run('py', ['--version']);
        if (resultFallback.exitCode == 0) {
          _pythonInstalled = true;
          await _checkPygameInstallation();
          return;
        }
      }
      
      _pythonInstalled = false;
    } catch (e) {
      _pythonInstalled = false;
    }
    
    notifyListeners();
  }
  
  String _getPythonCommand() {
    if (Platform.isMacOS || Platform.isLinux) {
      return 'python3';
    } else if (Platform.isWindows) {
      return 'python';
    }
    return 'python'; // Default fallback
  }
  
  String _getPipCommand() {
    if (Platform.isMacOS || Platform.isLinux) {
      return 'pip3';
    } else if (Platform.isWindows) {
      return 'pip';
    }
    return 'pip'; // Default fallback
  }
  
  Future<void> _checkPygameInstallation() async {
    try {
      final pythonCmd = _getPythonCommand();
      final result = await Process.run(
        pythonCmd, 
        ['-c', 'import pygame; print("Pygame installed")']
      );
      _pygameInstalled = result.exitCode == 0 && 
                         result.stdout.toString().contains("Pygame installed");
    } catch (e) {
      _pygameInstalled = false;
    }
    
    notifyListeners();
  }
  
  Future<bool> _checkHomebrewInstallation() async {
    try {
      final result = await Process.run('brew', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _checkChocolateyInstallation() async {
    try {
      final result = await Process.run('choco', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> installPython() async {
    _isInstallingPython = true;
    _setLoading(true, "Preparing to install Python...");
    _setProgress(10);
    
    if (Platform.isMacOS) {
      await _installPythonMac();
    } else if (Platform.isWindows) {
      await _installPythonWindows();
    } else if (Platform.isLinux) {
      await _installPythonLinux();
    } else {
      _setLoading(false, "Unsupported platform for automatic installation");
    }
    
    _isInstallingPython = false;
    notifyListeners();
  }
  
  Future<void> _installPythonMac() async {
    // macOS automatic installation using Homebrew
    try {
      // Check if Homebrew is installed
      bool hasHomebrew = await _checkHomebrewInstallation();
      
      if (!hasHomebrew) {
        _setLoading(true, "Homebrew is required to install Python. Opening installation instructions...");
        await launchUrl(Uri.parse(homebrewUrl));
        _setLoading(false, "Please install Homebrew, then try again");
        return;
      }
      
      _setLoading(true, "Installing Python via Homebrew...");
      _setProgress(30);
      
      // Install Python with Homebrew
      final installProcess = await Process.start('brew', ['install', 'python3']);
      
      // Listen to stdout to provide updates
      installProcess.stdout.transform(utf8.decoder).listen((data) {
        _setLoading(true, "Installing Python: $data");
      });
      
      // Listen to stderr for errors
      installProcess.stderr.transform(utf8.decoder).listen((data) {
        _setLoading(true, "Python installation: $data");
      });
      
      // Wait for process to complete
      final exitCode = await installProcess.exitCode;
      
      if (exitCode == 0) {
        _setProgress(90);
        _setLoading(true, "Python installed successfully. Verifying installation...");
        await _checkPythonInstallation();
        if (_pythonInstalled) {
          _setLoading(false, "Python installed successfully!");
        } else {
          _setLoading(false, "Python installation completed, but verification failed. Try restarting the app.");
        }
      } else {
        _setLoading(false, "Failed to install Python via Homebrew. Try installing manually.");
        await launchUrl(Uri.parse(macOSPythonUrl));
      }
    } catch (e) {
      _setLoading(false, "Error during Python installation: $e");
      // Fallback to manual installation
      await launchUrl(Uri.parse(macOSPythonUrl));
    }
  }
  
  Future<void> _installPythonWindows() async {
    try {
      bool hasChocolatey = await _checkChocolateyInstallation();
      
      if (hasChocolatey) {
        _setLoading(true, "Installing Python via Chocolatey...");
        _setProgress(30);
        
        // Use PowerShell to run as admin
        final installProcess = await Process.start('powershell', [
          'Start-Process', '-FilePath', 'choco', 
          '-ArgumentList', 'install python --version=3.11.7 -y', 
          '-Verb', 'RunAs', '-Wait'
        ]);
        
        installProcess.stdout.transform(utf8.decoder).listen((data) {
          _setLoading(true, "Installing Python: $data");
        });
        
        installProcess.stderr.transform(utf8.decoder).listen((data) {
          _setLoading(true, "Python installation: $data");
        });
        
        final exitCode = await installProcess.exitCode;
        
        if (exitCode == 0) {
          _setProgress(90);
          _setLoading(true, "Python installed. Verifying installation...");
          await _checkPythonInstallation();
          if (_pythonInstalled) {
            _setLoading(false, "Python installed successfully!");
          } else {
            _setLoading(false, "Python installation completed, but verification failed.");
          }
          return;
        }
      }
      
      // If Chocolatey is not installed or installation failed, download the installer
      _setLoading(true, "Launching Python installer...");
      
      // Direct download of Python installer
      final downloadUrl = "https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe";
      final tempDir = await getTemporaryDirectory();
      final installerPath = '${tempDir.path}/python_installer.exe';
      
      // Download the installer
      _setLoading(true, "Downloading Python installer...");
      
      final response = await http.get(Uri.parse(downloadUrl));
      final file = File(installerPath);
      await file.writeAsBytes(response.bodyBytes);
      
      _setLoading(true, "Running Python installer. Follow the on-screen instructions.");
      
      // Run the installer
      await Process.start(
        installerPath, 
        ['/quiet', 'InstallAllUsers=1', 'PrependPath=1'], 
        runInShell: true,
        mode: ProcessStartMode.detached,
      );
      
      _setLoading(false, "Python installer launched. Please complete installation and restart the app.");
    } catch (e) {
      _setLoading(false, "Error installing Python: $e. Opening download page.");
      await launchUrl(Uri.parse(windowsPythonUrl));
    }
  }
  
  Future<void> _installPythonLinux() async {
    try {
      // Try to detect package manager
      bool hasApt = await _checkCommandExists('apt');
      bool hasDnf = await _checkCommandExists('dnf');
      bool hasYum = await _checkCommandExists('yum');
      bool hasPacman = await _checkCommandExists('pacman');
      
      if (hasApt) {
        // Debian/Ubuntu
        _setLoading(true, "Installing Python via apt...");
        final result = await Process.run('sudo', ['apt', 'install', 'python3', 'python3-pip', '-y']);
        if (result.exitCode == 0) {
          _setLoading(true, "Python installed. Verifying...");
          await _checkPythonInstallation();
          if (_pythonInstalled) {
            _setLoading(false, "Python installed successfully!");
          } else {
            _setLoading(false, "Installation completed, but verification failed.");
          }
          return;
        }
      } else if (hasDnf) {
        // Fedora/RHEL 8+
        _setLoading(true, "Installing Python via dnf...");
        final result = await Process.run('sudo', ['dnf', 'install', 'python3', 'python3-pip', '-y']);
        if (result.exitCode == 0) {
          await _checkPythonInstallation();
          _setLoading(false, "Python installed successfully!");
          return;
        }
      } else if (hasYum) {
        // CentOS/RHEL
        _setLoading(true, "Installing Python via yum...");
        final result = await Process.run('sudo', ['yum', 'install', 'python3', 'python3-pip', '-y']);
        if (result.exitCode == 0) {
          await _checkPythonInstallation();
          _setLoading(false, "Python installed successfully!");
          return;
        }
      } else if (hasPacman) {
        // Arch Linux
        _setLoading(true, "Installing Python via pacman...");
        final result = await Process.run('sudo', ['pacman', '-S', 'python', 'python-pip', '--noconfirm']);
        if (result.exitCode == 0) {
          await _checkPythonInstallation();
          _setLoading(false, "Python installed successfully!");
          return;
        }
      }
      
      // If automatic installation failed
      _setLoading(false, "Could not install Python automatically");
      await launchUrl(Uri.parse(linuxPythonInfo));
    } catch (e) {
      _setLoading(false, "Error: $e");
      await launchUrl(Uri.parse(linuxPythonInfo));
    }
  }
  
  Future<bool> _checkCommandExists(String command) async {
    try {
      final result = await Process.run('which', [command]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> installPygame() async {
    if (!_pythonInstalled) {
      _setLoading(false, "Python must be installed first");
      return;
    }
    
    _isInstallingPygame = true;
    _setLoading(true, "Installing Pygame...");
    _setProgress(10);
    
    try {
      final pythonCmd = _getPythonCommand();
      final pipCmd = _getPipCommand();
      
      if (Platform.isMacOS) {
        await _installPygameMac(pythonCmd, pipCmd);
      } else if (Platform.isWindows) {
        await _installPygameWindows(pythonCmd, pipCmd);
      } else if (Platform.isLinux) {
        await _installPygameLinux(pythonCmd, pipCmd);
      } else {
        _setLoading(false, "Unsupported platform for automatic installation");
      }
    } catch (e) {
      _setLoading(false, "Failed to install Pygame: $e");
    }
    
    _isInstallingPygame = false;
    notifyListeners();
  }
  
  Future<void> _installPygameMac(String pythonCmd, String pipCmd) async {
    try {
      // On macOS, install pygame dependencies first via Homebrew
      _setLoading(true, "Installing Pygame dependencies...");
      _setProgress(30);
      
      try {
        // Check if the user needs xcode command line tools
        await Process.run('xcode-select', ['--install']);
      } catch (e) {
        // Ignore error if xcode command line tools are already installed
      }
      
      // Check for Homebrew
      bool hasHomebrew = await _checkHomebrewInstallation();
      if (!hasHomebrew) {
        _setLoading(true, "Homebrew is required for Pygame dependencies. Opening installation instructions...");
        await launchUrl(Uri.parse(homebrewUrl));
        _setLoading(false, "Please install Homebrew, then try again");
        return;
      }
      
      // Install SDL and other dependencies
      await Process.run('brew', ['install', 'sdl2', 'sdl2_image', 'sdl2_mixer', 'sdl2_ttf', 'pkg-config']);
      _setProgress(60);
    } catch (e) {
      _setLoading(true, "Failed to install dependencies, attempting direct Pygame installation...");
    }
    
    // Proceed with Pygame installation
    await _installPygameWithPip(pythonCmd, pipCmd);
  }
  
  Future<void> _installPygameWindows(String pythonCmd, String pipCmd) async {
    // Windows typically doesn't need extra dependencies
    await _installPygameWithPip(pythonCmd, pipCmd);
  }
  
  Future<void> _installPygameLinux(String pythonCmd, String pipCmd) async {
    try {
      // Install SDL dependencies based on package manager
      _setLoading(true, "Installing Pygame dependencies...");
      _setProgress(30);
      
      bool hasApt = await _checkCommandExists('apt');
      bool hasDnf = await _checkCommandExists('dnf');
      bool hasYum = await _checkCommandExists('yum');
      bool hasPacman = await _checkCommandExists('pacman');
      
      if (hasApt) {
        await Process.run('sudo', [
          'apt', 'install', '-y', 
          'libsdl2-dev', 'libsdl2-image-dev', 'libsdl2-mixer-dev', 
          'libsdl2-ttf-dev', 'libfreetype6-dev', 'libportmidi-dev'
        ]);
      } else if (hasDnf || hasYum) {
        String pkgManager = hasDnf ? 'dnf' : 'yum';
        await Process.run('sudo', [
          pkgManager, 'install', '-y',
          'SDL2-devel', 'SDL2_image-devel', 'SDL2_mixer-devel',
          'SDL2_ttf-devel', 'freetype-devel', 'portmidi-devel'
        ]);
      } else if (hasPacman) {
        await Process.run('sudo', [
          'pacman', '-S', '--noconfirm',
          'sdl2', 'sdl2_image', 'sdl2_mixer', 'sdl2_ttf', 'freetype2', 'portmidi'
        ]);
      }
      
      _setProgress(60);
    } catch (e) {
      _setLoading(true, "Failed to install dependencies, attempting direct Pygame installation...");
    }
    
    // Proceed with Pygame installation
    await _installPygameWithPip(pythonCmd, pipCmd);
  }
  
  Future<void> _installPygameWithPip(String pythonCmd, String pipCmd) async {
    // Install pygame using pip
    _setLoading(true, "Installing Pygame via pip...");
    _setProgress(70);
    
    List<String> args = ['-m', 'pip', 'install', 'pygame'];
    
    // Add user flag on non-Windows platforms to avoid permission issues
    if (!Platform.isWindows) {
      args.add('--user');
    }
    
    final installProcess = await Process.start(pythonCmd, args);
    
    // Listen to stdout to provide updates
    installProcess.stdout.transform(utf8.decoder).listen((data) {
      _setLoading(true, "Installing Pygame: $data");
    });
    
    // Listen to stderr for errors
    installProcess.stderr.transform(utf8.decoder).listen((data) {
      _setLoading(true, "Pygame installation: $data");
    });
    
    // Wait for process to complete
    final exitCode = await installProcess.exitCode;
    _setProgress(90);
    
    if (exitCode == 0) {
      _setLoading(true, "Pygame installed. Verifying...");
      await _checkPygameInstallation();
      if (_pygameInstalled) {
        _setLoading(false, "Pygame installed successfully!");
      } else {
        _setLoading(false, "Installation completed, but verification failed.");
      }
    } else {
      _setLoading(false, "Failed to install Pygame. Check your Python installation.");
    }
  }

  // Map to store installed app details (including local path info)
  Map<String, dynamic> _installedAppsData = {};
  
  // Method to load installed apps data from JSON file
  Future<void> _loadInstalledAppsData() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final appsDataFile = File('${appDir.path}/$installedAppsFile');
      
      if (await appsDataFile.exists()) {
        final jsonString = await appsDataFile.readAsString();
        _installedAppsData = json.decode(jsonString);
      } else {
        _installedAppsData = {};
      }
    } catch (e) {
      _installedAppsData = {};
      _setLoading(false, "Failed to load installed apps data: $e");
    }
  }
  
  // Method to save installed apps data to JSON file
  Future<void> _saveInstalledAppsData() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final appsDataFile = File('${appDir.path}/$installedAppsFile');
      
      final jsonString = json.encode(_installedAppsData);
      await appsDataFile.writeAsString(jsonString);
    } catch (e) {
      _setLoading(false, "Failed to save installed apps data: $e");
    }
  }

  Future<void> loadApps() async {
    _setLoading(true, "Loading apps from repository...");
    print("Attempting to load apps from: $appsJsonUrl");
    
    try {
      // Load from GitHub repository
      final Uri uri = Uri.parse(appsJsonUrl);
      
      try {
        // First attempt with timeout
        _setLoading(true, "Connecting to repository...");
        final response = await http.get(uri)
            .timeout(const Duration(seconds: 15));
        
        if (response.statusCode == 200) {
          print("HTTP 200 OK - Response received with length: ${response.body.length}");
          _setLoading(true, "Parsing response data...");
          
          try {
            final dynamic jsonData = json.decode(response.body);
            
            if (jsonData is Map<String, dynamic>) {
              // Correct any download URLs in the data before storing it
              jsonData.forEach((appName, appInfo) {
                if (appInfo is Map<String, dynamic> && appInfo.containsKey('download_url')) {
                  String downloadUrl = appInfo['download_url'].toString().trim();
                  
                  // Replace github.com/user/repo/raw/ with raw.githubusercontent.com/user/repo/
                  if (downloadUrl.contains('github.com') && downloadUrl.contains('/raw/')) {
                    final regex = RegExp(r'https://github\.com/([^/]+)/([^/]+)/raw/');
                    final match = regex.firstMatch(downloadUrl);
                    if (match != null) {
                      final user = match.group(1)!;
                      final repo = match.group(2)!;
                      final newBaseUrl = 'https://raw.githubusercontent.com/$user/$repo/';
                      downloadUrl = downloadUrl.replaceFirst(regex, newBaseUrl);
                      print("Fixed download URL for $appName: $downloadUrl");
                      appInfo['download_url'] = downloadUrl;
                    }
                  }
                }
              });
              
              _apps = jsonData;
              print("Successfully parsed JSON data with ${_apps.length} apps");
            } else {
              print("ERROR: Response is not a Map: ${jsonData.runtimeType}");
              _setLoading(true, "Invalid response format: ${jsonData.runtimeType}");
              _apps = {};
            }
            
            // Save to local cache for offline access
            _saveAppsToCache();
          } catch (parseError) {
            print("JSON parsing error: $parseError");
            print("Response body preview: ${response.body.substring(0, min(200, response.body.length))}...");
            throw parseError;
          }
        } else {
          print("HTTP Error: ${response.statusCode}");
          print("Response body: ${response.body}");
          throw HttpException("Failed to fetch apps: HTTP ${response.statusCode}");
        }
      } catch (e) {
        // Handle network errors, timeouts, and SSL issues
        print("Network error: $e");
        String errorMessage = e.toString();
        _setLoading(true, "Repository access error: ${errorMessage.substring(0, errorMessage.length > 50 ? 50 : errorMessage.length)}...");
        
        // If error indicates SSL/certificate issue (like 443)
        if (errorMessage.toLowerCase().contains("certificate") || 
            errorMessage.toLowerCase().contains("ssl") ||
            errorMessage.toLowerCase().contains("handshake") ||
            errorMessage.toLowerCase().contains("443")) {
          _setLoading(true, "SSL/Certificate error detected. Trying backup method...");
        }
        
        // Try to load from local cache
        await _loadAppsFromCache();
      }
      
      // Ensure all apps have a category
      if (_apps.isNotEmpty) {
        _apps.forEach((appName, appInfo) {
          if (appInfo['category'] == null) {
            // Default category based on tags
            final tags = (appInfo['tags'] as List<dynamic>?)?.map((tag) => tag.toString()).toList() ?? [];
            
            if (tags.contains('game') || tags.contains('games')) {
              appInfo['category'] = 'games';
            } else if (tags.contains('education') || tags.contains('learning')) {
              appInfo['category'] = 'education';
            } else if (tags.contains('media') || tags.contains('video') || tags.contains('audio')) {
              appInfo['category'] = 'media';
            } else if (tags.contains('development') || tags.contains('coding')) {
              appInfo['category'] = 'development';
            } else {
              appInfo['category'] = 'utilities';
            }
          }
        });
      } else {
        print("WARNING: _apps map is empty after loading");
      }
      
      _updateAvailableTags();
      _setLoading(false, "Found ${_apps.length} apps");
    } catch (e) {
      print("Exception in loadApps: $e");
      _setLoading(false, "Failed to load apps: $e");
    }
  }
  
  // Helper method to save apps to cache
  Future<void> _saveAppsToCache() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final cachedAppsFile = File('${appDir.path}/cached_apps.json');
      final jsonString = json.encode(_apps);
      await cachedAppsFile.writeAsString(jsonString);
    } catch (e) {
      // Silently handle caching error
      print("Failed to save apps cache: $e");
    }
  }
  
  // Helper method to load apps from cache
  Future<void> _loadAppsFromCache() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final cachedAppsFile = File('${appDir.path}/cached_apps.json');
      
      if (await cachedAppsFile.exists()) {
        final jsonString = await cachedAppsFile.readAsString();
        _apps = json.decode(jsonString);
        _setLoading(true, "Loaded apps from local cache");
      } else {
        // If no cache exists, create an empty apps map
        _apps = {};
        _setLoading(true, "No apps cache found. Please check your internet connection and try again.");
        
        // Try to connect with a different method (direct HTTPS request)
        _tryAlternativeConnection();
      }
    } catch (e) {
      // Create an empty map as a last resort
      _apps = {};
      _setLoading(true, "Failed to load apps. Please check your internet connection and try again.");
    }
  }
  
  // Try an alternative connection method for fetching apps
  Future<void> _tryAlternativeConnection() async {
    try {
      // Try a different HTTP client or approach
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(appsJsonUrl));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        _apps = json.decode(responseBody);
        _setLoading(true, "Loaded apps using alternative connection");
        
        // Save to cache
        _saveAppsToCache();
      }
    } catch (e) {
      // Silently handle alternative connection failure
    }
  }
  
  Future<void> loadInstalledApps() async {
    final appDir = await getApplicationSupportDirectory();
    final appsDir = Directory('${appDir.path}/apps');
    
    if (await appsDir.exists()) {
      final List<FileSystemEntity> entities = await appsDir.list().toList();
      _installedApps = entities
          .where((entity) => entity is Directory)
          .map((entity) => entity.path.split(Platform.pathSeparator).last)
          .toList();
    } else {
      _installedApps = [];
    }
    
    notifyListeners();
  }
  
  Future<void> installApp(String appName) async {
    if (!_pythonInstalled) {
      _setLoading(false, "Python must be installed first");
      return;
    }
    
    final appInfo = _apps[appName];
    if (appInfo == null) {
      _setLoading(false, "App information not found");
      return;
    }
    
    _setLoading(true, "Installing $appName...");
    _setProgress(0.0);
    
    // Get download URL and clean it
    final String rawDownloadUrl = appInfo['download_url'];
    // Trim any whitespace to fix " https://..." URLs
    final String downloadUrl = rawDownloadUrl.trim();
    
    print("Download URL for $appName: '$downloadUrl'");
    if (rawDownloadUrl != downloadUrl) {
      print("URL was trimmed (originally: '$rawDownloadUrl')");
    }
    
    // Create app directory
    final appDir = await getApplicationSupportDirectory();
    final appPath = '${appDir.path}/apps/$appName';
    final appDirectory = Directory(appPath);
    if (!await appDirectory.exists()) {
      await appDirectory.create(recursive: true);
    }
    
    // Download app
    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/$appName.zip';
    
    try {
      // Download zip file with better error handling
      _setLoading(true, "Downloading $appName...");
      try {
        final downloadUri = Uri.parse(downloadUrl);
        final response = await http.get(downloadUri)
            .timeout(const Duration(seconds: 60)); // Longer timeout for downloads
        
        if (response.statusCode == 200) {
          final file = File(zipPath);
          await file.writeAsBytes(response.bodyBytes);
          _setProgress(40.0);
        } else {
          throw HttpException("Failed to download $appName: HTTP ${response.statusCode}");
        }
      } catch (downloadError) {
        String errorMessage = downloadError.toString();
        
        // Check if the error is related to SSL/certificates
        if (errorMessage.toLowerCase().contains("certificate") || 
            errorMessage.toLowerCase().contains("ssl") ||
            errorMessage.toLowerCase().contains("handshake") ||
            errorMessage.toLowerCase().contains("443")) {
          _setLoading(false, "SSL certificate error when downloading $appName. Please check your internet connection and try again.");
          return;
        } else {
          _setLoading(false, "Failed to download $appName: $downloadError");
          return;
        }
      }
      
      // Extract zip file
      _setLoading(true, "Extracting $appName...");
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        _setLoading(false, "Download file not found for $appName");
        return;
      }
      
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      _setProgress(60.0);
      
      // Track if we found the src directory
      bool hasSrcDir = false;
      String srcPath = '';
      
      print("Extracting files for $appName:");
      
      // First scan the archive to understand the structure
      bool hasRootDir = false;
      String rootDirName = '';
      Set<String> topLevelDirs = {};
      
      for (final file in archive) {
        final filename = file.name;
        
        // Skip directories that start with "__" or "."
        if (filename.startsWith('__') || filename.startsWith('.')) {
          continue;
        }
        
        // Check if there's a root directory structure
        final parts = filename.split('/');
        if (parts.length > 1 && parts[0].isNotEmpty) {
          topLevelDirs.add(parts[0]);
        }
      }
      
      // If there's a single top-level directory, consider it a root dir
      if (topLevelDirs.length == 1) {
        hasRootDir = true;
        rootDirName = topLevelDirs.first;
        print("Archive has root directory: $rootDirName");
      }
      
      // Now extract files
      for (final file in archive) {
        final filename = file.name;
        print("  File: $filename");
        
        // Adjust filename if extracting from a root directory
        String targetPath = filename;
        if (hasRootDir && filename.startsWith('$rootDirName/')) {
          targetPath = filename.substring(rootDirName.length + 1);
        }
        
        if (file.isFile) {
          final data = file.content as List<int>;
          final fullPath = '$appPath/$targetPath';
          File(fullPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
            
          // Check if this file is in the src directory
          if (targetPath.startsWith('src/') || filename.startsWith('$rootDirName/src/')) {
            hasSrcDir = true;
            srcPath = '$appPath/src';
            print("  Found src directory file: $targetPath");
          }
          
          // Check for main.py at various levels
          final baseName = path.basename(targetPath).toLowerCase();
          if (baseName == 'main.py') {
            print("  Found main.py at: $targetPath");
          }
        } else {
          final dirPath = '$appPath/$targetPath';
          await Directory(dirPath).create(recursive: true);
          
          // Check if this is the src directory
          if (targetPath == 'src/' || targetPath == 'src' || 
              filename == '$rootDirName/src/' || filename == '$rootDirName/src') {
            hasSrcDir = true;
            srcPath = '$appPath/src';
            print("  Found src directory: $targetPath");
          }
        }
      }
      
      // If no src directory was explicitly found, but we have Python files at the root
      // consider the app directory itself as the src directory
      if (!hasSrcDir) {
        final rootFiles = await Directory(appPath).list().toList();
        for (final file in rootFiles) {
          if (file is File && file.path.endsWith('.py')) {
            print("  Found Python file at root: ${file.path}");
            hasSrcDir = true;
            srcPath = appPath;
            break;
          }
        }
      }
      
      print("Extraction complete, hasSrcDir=$hasSrcDir, srcPath=$srcPath");
      _setProgress(80.0);
      
      // Install requirements if needed
      final reqFile = File('$appPath/requirements.txt');
      if (await reqFile.exists()) {
        _setLoading(true, "Installing dependencies for $appName...");
        
        final pythonCmd = _getPythonCommand();
        final pipArgs = ['-m', 'pip', 'install', '-r', reqFile.path];
        
        // Add user flag on non-Windows platforms
        if (!Platform.isWindows) {
          pipArgs.add('--user');
        }
        
        try {
          final result = await Process.run(pythonCmd, pipArgs);
          if (result.exitCode != 0) {
            _setLoading(true, "Warning: Some dependencies may not have installed correctly.");
          }
        } catch (pipError) {
          _setLoading(true, "Warning: Error installing dependencies: $pipError");
        }
      }
      
      // Cleanup
      await File(zipPath).delete();
      
      // Store installed app data including path to src directory
      _installedAppsData[appName] = {
        ...appInfo, // Store all original app info
        'installation_path': appPath,
        'src_path': hasSrcDir ? srcPath : appPath, // Use src directory if found, otherwise use root
        'installation_date': DateTime.now().toIso8601String(),
      };
      
      // Save the updated installed apps data
      await _saveInstalledAppsData();
      
      // Add to installed apps list immediately
      if (!_installedApps.contains(appName)) {
        _installedApps.add(appName);
      }
      
      // Also update the full list
      await loadInstalledApps();
      
      _setLoading(false, "$appName installed successfully");
      _setProgress(100);
    } catch (e) {
      _setLoading(false, "Failed to install $appName: $e");
      
      // Cleanup failed installation
      try {
        final failedDir = Directory(appPath);
        if (await failedDir.exists()) {
          await failedDir.delete(recursive: true);
        }
        
        final tempFile = File(zipPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (cleanupError) {
        // Silently handle cleanup errors
      }
    }
  }
  
  Future<void> launchApp(String appName) async {
    _setLoading(true, "Launching $appName...");
    
    // Get installed app data
    final appData = _installedAppsData[appName];
    if (appData == null) {
      _setLoading(false, "App data not found. Try reinstalling the app.");
      return;
    }
    
    // Get the app paths
    final installPath = appData['installation_path'] as String?;
    final srcPath = appData['src_path'] as String?;
    
    if (installPath == null || srcPath == null) {
      _setLoading(false, "Invalid app data. Try reinstalling the app.");
      return;
    }
    
    try {
      // Set up games data directory for this app
      final appDir = await getApplicationSupportDirectory();
      final gameDataDir = Directory('${appDir.path}/games_data/$appName');
      if (!await gameDataDir.exists()) {
        await gameDataDir.create(recursive: true);
      }
      
      // Find a Python script to execute
      final pythonScript = await _findPythonScript(appName, srcPath, installPath);
      if (pythonScript == null) {
        _setLoading(false, "No Python script found for $appName. Try reinstalling the app.");
        return;
      }
      
      print("Launching $appName using script: $pythonScript");
      _setLoading(true, "Launching $appName using ${pythonScript.split('/').last}...");
      
      final pythonCmd = _getPythonCommand();
      
      // Set environment variables to help games find their data directory
      final env = {
        ...Platform.environment,
        'GAME_DATA_DIR': gameDataDir.path,
        'INNOVA_GAME_DATA': gameDataDir.path,
        'PYTHONPATH': srcPath,
      };
      
      await Process.start(
        pythonCmd, 
        [pythonScript],
        workingDirectory: path.dirname(pythonScript),
        environment: env,
        mode: ProcessStartMode.detached
      );
      
      _setLoading(false, "Launched $appName");
    } catch (e) {
      _setLoading(false, "Failed to launch $appName: $e");
    }
  }
  
  // Helper method to find the main Python script to execute
  Future<String?> _findPythonScript(String appName, String srcPath, String installPath) async {
    // Define a priority ordered list of paths to check
    final List<String> possiblePaths = [
      '$srcPath/main.py',
      '$srcPath/__main__.py',
      '$installPath/main.py',
      '$installPath/src/main.py',
      '$installPath/__main__.py',
    ];
    
    // First check known main file locations
    for (final path in possiblePaths) {
      if (await File(path).exists()) {
        print("Found main script at: $path");
        return path;
      }
    }
    
    // If specific main files not found, try to find any Python file in the src directory
    try {
      final srcDir = Directory(srcPath);
      final List<FileSystemEntity> files = await srcDir.list().toList();
      
      // First look for files with "main" in the name
      for (final file in files) {
        if (file is File && 
            file.path.endsWith('.py') && 
            path.basename(file.path).toLowerCase().contains('main')) {
          print("Found main-like script at: ${file.path}");
          return file.path;
        }
      }
      
      // Then look for any Python file
      for (final file in files) {
        if (file is File && file.path.endsWith('.py')) {
          print("Found Python script at: ${file.path}");
          return file.path;
        }
      }
    } catch (e) {
      print("Error searching src directory: $e");
    }
    
    // If still not found, search the entire installation directory recursively
    try {
      final installDir = Directory(installPath);
      await for (final entity in installDir.list(recursive: true)) {
        if (entity is File && 
            entity.path.endsWith('.py') && 
            !entity.path.contains('__pycache__')) {
          
          // Prefer files with "main" in the name
          if (path.basename(entity.path).toLowerCase().contains('main')) {
            print("Found main-like script in installation directory: ${entity.path}");
            return entity.path;
          }
        }
      }
      
      // Last resort: any Python file
      await for (final entity in installDir.list(recursive: true)) {
        if (entity is File && 
            entity.path.endsWith('.py') && 
            !entity.path.contains('__pycache__')) {
          print("Found Python script in installation directory: ${entity.path}");
          return entity.path;
        }
      }
    } catch (e) {
      print("Error searching installation directory: $e");
    }
    
    // No Python script found
    return null;
  }
  
  Future<void> uninstallApp(String appName) async {
    _setLoading(true, "Uninstalling $appName...");
    
    final appDir = await getApplicationSupportDirectory();
    final appPath = '${appDir.path}/apps/$appName';
    
    try {
      final directory = Directory(appPath);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      
      // Remove app data from installed apps data
      _installedAppsData.remove(appName);
      
      // Save the updated installed apps data
      await _saveInstalledAppsData();
      
      // Remove from installed apps list immediately
      _installedApps.removeWhere((name) => name == appName);
      notifyListeners();
      
      // Also update the full list
      await loadInstalledApps();
      
      _setLoading(false, "$appName uninstalled successfully");
    } catch (e) {
      _setLoading(false, "Failed to uninstall $appName: $e");
    }
  }

  // Category and tag management
  void setCategory(String categoryId) {
    _selectedCategory = categoryId;
    notifyListeners();
  }
  
  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }
  
  void clearTags() {
    _selectedTags = {};
    notifyListeners();
  }
  
  Category getCategoryById(String id) {
    return categories.firstWhere(
      (category) => category.id == id,
      orElse: () => categories.firstWhere((c) => c.id == 'other')
    );
  }
  
  bool isAppInSelectedCategory(String appName, Map<String, dynamic> appInfo) {
    if (_selectedCategory == 'all') return true;
    
    final appCategory = appInfo['category'] as String? ?? 'utilities';
    return appCategory == _selectedCategory;
  }
  
  bool doesAppMatchSelectedTags(String appName, Map<String, dynamic> appInfo) {
    if (_selectedTags.isEmpty) return true;
    
    final appTags = (appInfo['tags'] as List<dynamic>?)?.map((tag) => tag.toString()).toList() ?? [];
    
    // Check if any of the selected tags are in the app's tags
    for (final tag in _selectedTags) {
      if (appTags.contains(tag)) {
        return true;
      }
    }
    
    return false;
  }
  
  bool doesAppMatchSearchQuery(String appName, Map<String, dynamic> appInfo, String searchQuery) {
    if (searchQuery.isEmpty) return true;
    
    final query = searchQuery.toLowerCase();
    final name = appName.toLowerCase();
    final description = appInfo['description']?.toString().toLowerCase() ?? '';
    final category = appInfo['category']?.toString().toLowerCase() ?? '';
    final tags = (appInfo['tags'] as List<dynamic>?)?.map((tag) => tag.toString().toLowerCase()).toList() ?? [];
    
    return name.contains(query) || 
           description.contains(query) ||
           category.contains(query) ||
           tags.any((tag) => tag.contains(query));
  }
  
  List<MapEntry<String, dynamic>> getFilteredApps(String searchQuery) {
    return _apps.entries.where((entry) {
      final appName = entry.key;
      final appInfo = entry.value;
      
      return isAppInSelectedCategory(appName, appInfo) && 
             doesAppMatchSelectedTags(appName, appInfo) &&
             doesAppMatchSearchQuery(appName, appInfo, searchQuery);
    }).toList();
  }
  
  List<MapEntry<String, dynamic>> getFilteredInstalledApps() {
    return _installedApps
        .map((appName) => MapEntry(appName, _apps[appName] ?? {'description': 'Local app'}))
        .where((entry) {
          return isAppInSelectedCategory(entry.key, entry.value) && 
                 doesAppMatchSelectedTags(entry.key, entry.value);
        })
        .toList();
  }
  
  void _updateAvailableTags() {
    Set<String> tags = {};
    
    _apps.forEach((appName, appInfo) {
      final appTags = (appInfo['tags'] as List<dynamic>?)?.map((tag) => tag.toString()).toList() ?? [];
      tags.addAll(appTags);
    });
    
    _availableTags = tags.toList()..sort();
    notifyListeners();
  }

  // Game Board Methods
  void selectGame(String? gameId) {
    _selectedGameId = gameId;
    if (gameId != null) {
      loadModsForGame(gameId);
    }
    notifyListeners();
  }
  
  Future<void> loadModsForGame(String gameId) async {
    if (!_installedApps.contains(gameId)) {
      // Cannot load mods for games that aren't installed
      return;
    }
    
    _isLoadingMods = true;
    notifyListeners();
    
    // Using ModManager to get mods
    final mods = _modManager.getModsForGame(gameId);
    
    _isLoadingMods = false;
    notifyListeners();
  }
  
  Future<void> toggleMod(String gameId, String modId, bool enabled) async {
    await _modManager.toggleMod(gameId, modId, enabled);
    notifyListeners();
  }
  
  Future<void> installMod(String gameId, String modId) async {
    _setLoading(true, "Installing mod ${modId}...");
    
    final result = await _modManager.installMod(gameId, modId);
    
    if (result) {
      _setLoading(false, "Mod installed successfully");
    } else {
      _setLoading(false, "Failed to install mod");
    }
  }
  
  Future<void> launchAppWithMods(String appName) async {
    // Check if game has mods
    if (!hasModsForGame(appName)) {
      // No mods, just launch normally
      return launchApp(appName);
    }
    
    _setLoading(true, "Launching $appName with mods...");
    
    // Get installed app data
    final appData = _installedAppsData[appName];
    if (appData == null) {
      _setLoading(false, "App data not found. Try reinstalling the app.");
      return;
    }
    
    // Get the app paths
    final installPath = appData['installation_path'] as String?;
    final srcPath = appData['src_path'] as String?;
    
    if (installPath == null || srcPath == null) {
      _setLoading(false, "Invalid app data. Try reinstalling the app.");
      return;
    }
    
    final pythonCmd = _getPythonCommand();
    await _modManager.launchGameWithMods(appName, pythonCmd);
    
    _setLoading(false, "Launched $appName with mods");
  }

  // Initialize the mod manager
  void _initModManager() async {
    final appDir = await getApplicationSupportDirectory();
    final modsJsonPath = '${appDir.path}/$installedAppsFile';
    _modManager = ModManager('${appDir.path}/apps', modsJsonUrl, modsJsonPath);
    
    // Initialize and fetch available mods
    await _modManager.init();
    _fetchAvailableMods();
  }
  
  void _fetchAvailableMods() async {
    _isLoadingMods = true;
    notifyListeners();
    
    await _modManager.fetchAvailableMods();
    
    _isLoadingMods = false;
    notifyListeners();
  }

  // Static helper to get AppModel from context
  static AppModel of(BuildContext context) {
    return Provider.of<AppModel>(context, listen: false);
  }
  
  // Method to get installed app data
  Map<String, dynamic>? getInstalledAppData(String appId) {
    return _installedAppsData[appId];
  }
  
  // Helper to check if an app is installed
  bool isAppInstalled(String appId) {
    return _installedApps.contains(appId);
  }
} 