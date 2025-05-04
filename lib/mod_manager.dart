import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'model.dart'; // Import GameMod from model.dart

/// Class to manage mods for games
class ModManager extends ChangeNotifier {
  final String appsPath;
  final String modsJsonUrl;
  final String modsJsonPath;
  
  bool _isLoading = false;
  Map<String, List<GameMod>> _installedMods = {};
  Map<String, List<GameMod>> _availableMods = {};
  
  ModManager(this.appsPath, this.modsJsonUrl, this.modsJsonPath);
  
  bool get isLoading => _isLoading;
  Map<String, List<GameMod>> get installedMods => _installedMods;
  Map<String, List<GameMod>> get availableMods => _availableMods;
  
  /// Get the installed mods for a specific game
  List<GameMod> getModsForGame(String gameId) {
    return _installedMods[gameId] ?? [];
  }
  
  /// Check if a game has any mods
  bool hasModsForGame(String gameId) {
    return (_installedMods[gameId]?.isNotEmpty ?? false) || 
           (_availableMods[gameId]?.isNotEmpty ?? false);
  }
  
  /// Initialize mods from the mods.json file
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Load mods data from file
      final modsFile = File(modsJsonPath);
      if (await modsFile.exists()) {
        final jsonString = await modsFile.readAsString();
        final Map<String, dynamic> modsData = json.decode(jsonString);
        
        if (modsData.containsKey('installed_mods')) {
          final List<dynamic> installedModsList = modsData['installed_mods'];
          
          // Process installed mods
          for (final modData in installedModsList) {
            if (modData is Map<String, dynamic> && modData.containsKey('game_id')) {
              final gameId = modData['game_id'] as String;
              final mod = GameMod.fromJson(modData);
              
              if (!_installedMods.containsKey(gameId)) {
                _installedMods[gameId] = [];
              }
              _installedMods[gameId]!.add(mod);
            }
          }
        }
      }
    } catch (e) {
      print("Error initializing mods: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Fetch available mods from the server
  Future<void> fetchAvailableMods() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final response = await http.get(Uri.parse(modsJsonUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        
        _availableMods = {};
        
        // Process each game's available mods
        jsonData.forEach((gameId, gameData) {
          if (gameData is Map<String, dynamic> && gameData['available_mods'] is List) {
            final availMods = (gameData['available_mods'] as List)
                .map((modJson) => GameMod.fromJson(modJson))
                .toList();
            _availableMods[gameId] = availMods;
          }
        });
        
        // Merge with existing installed mods
        _mergeModsData();
      }
    } catch (e) {
      print('Error fetching available mods: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Merges installed and available mods data
  void _mergeModsData() {
    // For each game with available mods
    _availableMods.forEach((gameId, availableMods) {
      final installedModsForGame = _installedMods[gameId] ?? [];
      
      // For each available mod
      for (final availableMod in availableMods) {
        // Check if it's already installed
        final installedModIndex = installedModsForGame.indexWhere((m) => m.id == availableMod.id);
        
        if (installedModIndex >= 0) {
          // Update available mod with installed status
          final installedMod = installedModsForGame[installedModIndex];
          final updatedMod = availableMod.copyWith(
            enabled: installedMod.enabled,
            installPath: installedMod.installPath,
            filesReplaced: installedMod.filesReplaced,
          );
          
          // Replace in available mods
          final index = _availableMods[gameId]!.indexWhere((m) => m.id == availableMod.id);
          if (index >= 0) {
            _availableMods[gameId]![index] = updatedMod;
          }
        }
      }
    });
  }
  
  /// Toggle a mod's enabled status
  Future<void> toggleMod(String gameId, String modId, bool enable) async {
    if (!_availableMods.containsKey(gameId)) {
      return;
    }
    
    final mods = _availableMods[gameId]!;
    final modIndex = mods.indexWhere((m) => m.id == modId);
    
    if (modIndex >= 0) {
      // Update mod
      final updatedMod = mods[modIndex].copyWith(enabled: enable);
      _availableMods[gameId]![modIndex] = updatedMod;
      
      // Update installed mods as well
      if (_installedMods.containsKey(gameId)) {
        final installedModIndex = _installedMods[gameId]!.indexWhere((m) => m.id == modId);
        if (installedModIndex >= 0) {
          _installedMods[gameId]![installedModIndex] = updatedMod;
        } else if (updatedMod.installPath != null) {
          // If not found but has install path, add to installed mods
          _installedMods.putIfAbsent(gameId, () => []).add(updatedMod);
        }
      } else if (updatedMod.installPath != null) {
        // If game not in installed mods but mod has install path
        _installedMods[gameId] = [updatedMod];
      }
      
      // Save to file
      await _saveModsData();
      notifyListeners();
    }
  }
  
  /// Install a mod from the available mods list
  Future<bool> installMod(String gameId, String modId) async {
    if (!_availableMods.containsKey(gameId)) {
      return false;
    }
    
    final mods = _availableMods[gameId]!;
    final modIndex = mods.indexWhere((m) => m.id == modId);
    
    if (modIndex < 0 || mods[modIndex].downloadUrl == null) {
      return false;
    }
    
    final mod = mods[modIndex];
    
    try {
      // Create directories
      final gameDir = Directory('$appsPath/$gameId');
      final modsDir = Directory('${gameDir.path}/mods');
      final modDir = Directory('${modsDir.path}/$modId');
      
      if (!await gameDir.exists()) {
        return false; // Game directory doesn't exist
      }
      
      if (!await modsDir.exists()) {
        await modsDir.create(recursive: true);
      }
      
      if (await modDir.exists()) {
        await modDir.delete(recursive: true); // Remove existing mod
      }
      
      await modDir.create(recursive: true);
      
      // Create directories for backups
      final backupDir = Directory('${modDir.path}/backup');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      // Download the mod
      final response = await http.get(Uri.parse(mod.downloadUrl!))
          .timeout(const Duration(seconds: 30));
          
      if (response.statusCode != 200) {
        throw HttpException("Failed to download mod: HTTP ${response.statusCode}");
      }
      
      // Save and extract zip file
      final tempDir = Directory.systemTemp;
      final zipFile = File('${tempDir.path}/$modId.zip');
      await zipFile.writeAsBytes(response.bodyBytes);
      
      // Extract zip
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Track replaced files
      final filesReplaced = <String>[];
      
      // Process each file in the archive
      for (final file in archive) {
        final filename = file.name;
        
        // Skip directories that start with __MACOSX or .DS_Store
        if (filename.startsWith('__MACOSX/') || 
            filename == '.DS_Store' || 
            filename.contains('/.DS_Store')) {
          continue;
        }
        
        // Handle directories
        if (file.isFile) {
          final destFile = File('${modDir.path}/$filename');
          final data = file.content as List<int>;
          
          // Create parent directories if needed
          await destFile.parent.create(recursive: true);
          await destFile.writeAsBytes(data);
          
          // If this file would replace a game file, back up the original
          if (!filename.startsWith('mod.json') && !filename.startsWith('README')) {
            final gameFile = File('${gameDir.path}/$filename');
            if (await gameFile.exists()) {
              // Back up the original file
              final backupFile = File('${backupDir.path}/$filename');
              await backupFile.parent.create(recursive: true);
              await gameFile.copy(backupFile.path);
              
              filesReplaced.add(filename);
            }
          }
        }
      }
      
      // Clean up
      await zipFile.delete();
      
      // Update mod information
      final updatedMod = mod.copyWith(
        enabled: true,
        installPath: modDir.path,
        filesReplaced: filesReplaced,
      );
      
      // Update available mods
      _availableMods[gameId]![modIndex] = updatedMod;
      
      // Update installed mods
      if (!_installedMods.containsKey(gameId)) {
        _installedMods[gameId] = [];
      }
      
      final installedModIndex = _installedMods[gameId]!.indexWhere((m) => m.id == modId);
      if (installedModIndex >= 0) {
        _installedMods[gameId]![installedModIndex] = updatedMod;
      } else {
        _installedMods[gameId]!.add(updatedMod);
      }
      
      // Save changes
      await _saveModsData();
      notifyListeners();
      
      return true;
    } catch (e) {
      print("Error installing mod: $e");
      return false;
    }
  }
  
  /// Save the current mods data to the mods.json file
  Future<void> _saveModsData() async {
    try {
      final installedModsList = <Map<String, dynamic>>[];
      
      // Flatten installed mods map to a list
      _installedMods.forEach((gameId, mods) {
        for (final mod in mods) {
          final modJson = mod.toJson();
          installedModsList.add(modJson);
        }
      });
      
      final jsonData = {
        'installed_mods': installedModsList,
      };
      
      final modsFile = File(modsJsonPath);
      await modsFile.writeAsString(json.encode(jsonData));
    } catch (e) {
      print("Error saving mods data: $e");
    }
  }
  
  /// Launch a game with enabled mods
  Future<void> launchGameWithMods(String gameId, String pythonCmd) async {
    if (!_installedMods.containsKey(gameId)) {
      return;
    }
    
    final enabledMods = _installedMods[gameId]!.where((m) => m.enabled).toList();
    if (enabledMods.isEmpty) {
      return;
    }
    
    try {
      final gameDir = Directory('$appsPath/$gameId');
      final srcPath = '${gameDir.path}/src';
      
      // Set up games data directory for this game
      final appSupportDir = Directory(p.dirname(p.dirname(appsPath)));
      final gameDataDir = Directory('${appSupportDir.path}/games_data/$gameId');
      if (!await gameDataDir.exists()) {
        await gameDataDir.create(recursive: true);
      }
      
      // Temporarily replace files with modded versions
      final replacedFiles = <String, String>{}; // original -> temp backup
      
      for (final mod in enabledMods) {
        if (mod.installPath != null && mod.filesReplaced != null) {
          for (final filename in mod.filesReplaced!) {
            final originalFile = File('${gameDir.path}/$filename');
            final modFile = File('${mod.installPath!}/$filename');
            
            if (await originalFile.exists() && await modFile.exists()) {
              // Create backup if not already backed up
              if (!replacedFiles.containsKey(originalFile.path)) {
                final tempBackup = '${originalFile.path}.vanilla';
                await originalFile.copy(tempBackup);
                replacedFiles[originalFile.path] = tempBackup;
              }
              
              // Replace with mod file
              await modFile.copy(originalFile.path);
            }
          }
        }
      }
      
      // Find a Python script to execute
      final mainPyFile = File('$srcPath/main.py');
      final appPyFile = File('$srcPath/app.py');
      final gameFile = File('$srcPath/game.py');
      
      String? scriptPath;
      if (await mainPyFile.exists()) {
        scriptPath = mainPyFile.path;
      } else if (await appPyFile.exists()) {
        scriptPath = appPyFile.path;
      } else if (await gameFile.exists()) {
        scriptPath = gameFile.path;
      } else {
        // Try to find any Python file in the src directory
        final srcDir = Directory(srcPath);
        await for (final entity in srcDir.list()) {
          if (entity is File && entity.path.endsWith('.py')) {
            scriptPath = entity.path;
            break;
          }
        }
      }
      
      if (scriptPath == null) {
        throw Exception("No Python script found for $gameId");
      }
      
      // Set environment variables
      final env = {
        ...Platform.environment,
        'GAME_DATA_DIR': gameDataDir.path,
        'INNOVA_GAME_DATA': gameDataDir.path,
        'PYTHONPATH': srcPath,
        'MODS_ENABLED': 'true',
        'ENABLED_MODS': enabledMods.map((m) => m.id).join(','),
      };
      
      // Launch the game
      await Process.start(
        pythonCmd, 
        [scriptPath],
        workingDirectory: srcPath,
        environment: env,
        mode: ProcessStartMode.detached
      );
      
      // Restore original files after a short delay
      await Future.delayed(const Duration(seconds: 2));
      for (final entry in replacedFiles.entries) {
        final originalFile = File(entry.key);
        final backupFile = File(entry.value);
        if (await backupFile.exists()) {
          await backupFile.copy(originalFile.path);
          await backupFile.delete();
        }
      }
    } catch (e) {
      print("Error launching game with mods: $e");
      // Try to restore files if error occurs
      rethrow;
    }
  }
} 