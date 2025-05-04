import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart' as window_size;
import 'dart:io' show Platform;
import 'dart:math';

import 'model.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set minimum window size on desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    window_size.setWindowTitle('Innova Launcher');
    window_size.setWindowMinSize(const Size(400, 600));
    window_size.setWindowMaxSize(Size.infinite);
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppModel(),
      child: const InnovaLauncher(),
    ),
  );
}

class InnovaLauncher extends StatelessWidget {
  const InnovaLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    
    return MaterialApp(
      title: 'Innova Launcher',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(isDark: appModel.isDarkMode),
      home: const LauncherHomePage(),
    );
  }
}

class LauncherHomePage extends StatefulWidget {
  const LauncherHomePage({super.key});

  @override
  LauncherHomePageState createState() => LauncherHomePageState();
}

class LauncherHomePageState extends State<LauncherHomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Track if this is the initial load
  bool _isFirstLoad = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add listener to reset category when switching tabs
    _tabController.addListener(_handleTabChange);
    
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    ));
    
    // Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });
  }
  
  // Handle tab change to reset category to 'all'
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final appModel = Provider.of<AppModel>(context, listen: false);
      if (appModel.selectedCategory != 'all') {
        appModel.setCategory('all');
        // Clear search when changing tabs
        searchController.clear();
      }
      
      // Clear selected game when changing tabs
      if (appModel.selectedGameId != null) {
        appModel.selectGame(null);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    final isDark = appModel.isDarkMode;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isVerySmallScreen = size.width < 400;
    final padding = EdgeInsets.symmetric(
      horizontal: isVerySmallScreen ? 8.0 : (isSmallScreen ? 12.0 : 16.0)
    );
    
    // Check if a game is selected for the game board
    final String? selectedGameId = appModel.selectedGameId;
    final bool showGameBoard = selectedGameId != null && _tabController.index == 1;
    
    // If this is the first load and we have data, animate
    if (_isFirstLoad && !appModel.isLoading && appModel.apps.isNotEmpty) {
      _isFirstLoad = false;
      _animationController.forward();
    }
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: isSmallScreen ? 48 : null,
        actions: [
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              );
            },
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return RotationTransition(
                    turns: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  key: ValueKey<bool>(isDark),
                ),
              ),
              onPressed: appModel.toggleTheme,
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              iconSize: isSmallScreen ? 20 : 24,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use a different layout for very wide screens
            if (constraints.maxWidth > 1200) {
              return _buildWideLayout(appModel, isDark, constraints, showGameBoard, selectedGameId);
            }
            
            // Normal layout for most screens
            return Column(
              children: [
                // Header with gradient - height adapts to screen size
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: GradientHeader(
                      title: 'Innova Launcher',
                      subtitle: 'Discover and run Python apps with ease',
                      isDark: isDark,
                      height: constraints.maxHeight * (isSmallScreen ? 0.12 : 0.15),
                    ),
                  ),
                ),
                
                // Tabs
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    color: isDark ? AppTheme.black : AppTheme.lightSurface,
                    child: TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(
                          text: isSmallScreen ? null : 'Store', 
                          icon: Icon(Icons.store, size: isSmallScreen ? 20 : 24),
                        ),
                        Tab(
                          text: isSmallScreen ? null : 'Library', 
                          icon: Icon(Icons.apps, size: isSmallScreen ? 20 : 24),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Python & Pygame installation checks
                if (!appModel.pythonInstalled)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: padding.copyWith(top: 16, bottom: 16),
                        child: StatusNotification(
                          isPython: true,
                          isInstalled: false,
                          onInstall: appModel.installPython,
                          isDark: isDark,
                          isCompact: isSmallScreen,
                          isInstalling: appModel.isInstallingPython,
                        ),
                      ),
                    ),
                  ),
                
                if (appModel.pythonInstalled && !appModel.pygameInstalled)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: padding.copyWith(bottom: 16),
                        child: StatusNotification(
                          isPython: false,
                          isInstalled: false,
                          onInstall: appModel.installPygame,
                          isDark: isDark,
                          isCompact: isSmallScreen,
                          isInstalling: appModel.isInstallingPygame,
                        ),
                      ),
                    ),
                  ),
                
                // Category Selection Scrollable Row - responsive height
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SizedBox(
                      height: isVerySmallScreen ? 70 : (isSmallScreen ? 80 : 100),
                      child: _buildCategorySelector(appModel, isDark, isSmallScreen),
                    ),
                  ),
                ),
                
                // Search and tag filter bar (only in Store tab)
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    return _tabController.index == 0 
                      ? FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              // Search Field
                              Padding(
                                padding: padding.copyWith(top: 8, bottom: 8),
                                child: TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    labelText: 'Search apps',
                                    prefixIcon: const Icon(Icons.search),
                                    contentPadding: isSmallScreen 
                                        ? const EdgeInsets.symmetric(vertical: 8, horizontal: 12)
                                        : null,
                                    suffixIcon: searchQuery.isNotEmpty 
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () => searchController.clear(),
                                        )
                                      : null,
                                  ),
                                ),
                              ),
                              
                              // Tags Filter
                              if (appModel.availableTags.isNotEmpty)
                                Padding(
                                  padding: padding.copyWith(bottom: 8),
                                  child: _buildTagsFilter(appModel, isDark, isSmallScreen),
                                ),
                            ],
                          ),
                        )
                      : Container();
                  },
                ),
                
                // Main content - expanded with TabBarView
                Expanded(
                  child: showGameBoard 
                      ? GameBoardView(
                          gameId: selectedGameId,
                          isDark: isDark,
                          onClose: () => appModel.selectGame(null),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // Store Tab
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildStoreTab(context, appModel, isSmallScreen),
                            ),
                            
                            // Library Tab
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildLibraryTab(context, appModel, isSmallScreen),
                            ),
                          ],
                        ),
                ),
              ],
            );
          }
        ),
      ),
      // Floating refresh button
      floatingActionButton: ScaleTransition(
        scale: _fadeAnimation,
        child: FloatingActionButton(
          onPressed: () {
            // Animated refresh
            _animateRefresh();
            appModel.loadApps();
            appModel.loadInstalledApps();
          },
          backgroundColor: isDark ? AppTheme.pink : AppTheme.blue,
          child: Icon(Icons.refresh, size: isSmallScreen ? 20 : 24),
          mini: isSmallScreen,
        ),
      ),
    );
  }
  
  // Animate refresh button
  void _animateRefresh() {
    // Create a temporary animation controller for the refresh animation
    final refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    refreshController.forward().then((_) {
      refreshController.dispose();
    });
    
    // Rerun the main animation
    _animationController.reset();
    _animationController.forward();
  }
  
  // Wide layout for large screens (desktop)
  Widget _buildWideLayout(
    AppModel appModel, 
    bool isDark, 
    BoxConstraints constraints,
    bool showGameBoard,
    String? selectedGameId,
  ) {
    final isSmallScreen = constraints.maxWidth < 1400;
    
    return Row(
      children: [
        // Left sidebar - fixed width
        Container(
          width: isSmallScreen ? 220 : 280,
          color: isDark ? AppTheme.darkGrey : Colors.grey[100],
          child: Column(
            children: [
              // Logo and header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.headerGradient(isDark: isDark),
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Innova Launcher',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: appModel.toggleTheme,
                          tooltip: isDark ? 'Light mode' : 'Dark mode',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Python App Launcher',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Navigation
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        'NAVIGATION',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black45,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Store tab
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _tabController.index == 0 
                            ? (isDark ? AppTheme.blue.withOpacity(0.15) : AppTheme.blue.withOpacity(0.1))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _tabController.index == 0
                              ? (isDark ? AppTheme.blue.withOpacity(0.5) : AppTheme.blue.withOpacity(0.3))
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        selected: _tabController.index == 0,
                        leading: Icon(
                          Icons.store,
                          color: _tabController.index == 0 
                              ? (isDark ? AppTheme.blue : AppTheme.blue) 
                              : null,
                        ),
                        title: Text(
                          'Store',
                          style: TextStyle(
                            fontWeight: _tabController.index == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: () {
                          if (_tabController.index != 0) {
                            _tabController.animateTo(0);
                            appModel.setCategory('all');
                          }
                        },
                        trailing: _tabController.index == 0 
                            ? Icon(
                                Icons.arrow_right,
                                color: isDark ? AppTheme.blue : AppTheme.blue,
                              ) 
                            : null,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Library tab
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _tabController.index == 1 
                            ? (isDark ? AppTheme.pink.withOpacity(0.15) : AppTheme.blue.withOpacity(0.1))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _tabController.index == 1
                              ? (isDark ? AppTheme.pink.withOpacity(0.5) : AppTheme.blue.withOpacity(0.3))
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        selected: _tabController.index == 1,
                        leading: Icon(
                          Icons.apps,
                          color: _tabController.index == 1 
                              ? (isDark ? AppTheme.pink : AppTheme.blue) 
                              : null,
                        ),
                        title: Text(
                          'My Library',
                          style: TextStyle(
                            fontWeight: _tabController.index == 1 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: () {
                          if (_tabController.index != 1) {
                            _tabController.animateTo(1);
                            appModel.setCategory('all');
                          }
                        },
                        trailing: _tabController.index == 1 
                            ? Icon(
                                Icons.arrow_right,
                                color: isDark ? AppTheme.pink : AppTheme.blue,
                              ) 
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Categories
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        'CATEGORIES',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black45,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    ...appModel.categories.map((category) {
                      final isSelected = category.id == appModel.selectedCategory;
                      
                      return ListTile(
                        selected: isSelected,
                        leading: Icon(
                          category.icon,
                          color: isSelected ? category.color : null,
                        ),
                        title: Text(category.name),
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: () => appModel.setCategory(category.id),
                      );
                    }).toList(),
                  ],
                ),
              ),
              
              if (appModel.availableTags.isNotEmpty && _tabController.index == 0)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8, right: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TAGS',
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : Colors.black45,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (appModel.selectedTags.isNotEmpty)
                                TextButton(
                                  onPressed: appModel.clearTags,
                                  child: Text('Clear', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        Expanded(
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: appModel.availableTags.map((tag) {
                                final isSelected = appModel.selectedTags.contains(tag);
                                
                                return FilterChip(
                                  label: Text(tag, style: TextStyle(fontSize: 12)),
                                  selected: isSelected,
                                  onSelected: (_) => appModel.toggleTag(tag),
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
              // Status display at bottom
              const Spacer(),
              if (!appModel.pythonInstalled || !appModel.pygameInstalled)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!appModel.pythonInstalled)
                        StatusNotification(
                          isPython: true,
                          isInstalled: false,
                          onInstall: appModel.installPython,
                          isDark: isDark,
                          isCompact: true,
                          isInstalling: appModel.isInstallingPython,
                        ),
                        
                      if (appModel.pythonInstalled && !appModel.pygameInstalled)
                        StatusNotification(
                          isPython: false,
                          isInstalled: false,
                          onInstall: appModel.installPygame,
                          isDark: isDark,
                          isCompact: true,
                          isInstalling: appModel.isInstallingPygame,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Right content area
        Expanded(
          child: Column(
            children: [
              // Header showing current tab
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _tabController.index == 0 
                        ? (isDark 
                            ? [AppTheme.blue.withOpacity(0.15), AppTheme.purple.withOpacity(0.05)] 
                            : [AppTheme.blue.withOpacity(0.1), Colors.white])
                        : (isDark 
                            ? [AppTheme.teal.withOpacity(0.15), AppTheme.darkGrey] 
                            : [AppTheme.teal.withOpacity(0.1), Colors.white]),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      showGameBoard 
                          ? 'Game Details'
                          : (_tabController.index == 0 ? 'Store' : 'My Library'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _tabController.index == 0 
                            ? (isDark ? AppTheme.blue : AppTheme.blue) 
                            : (isDark ? AppTheme.teal : AppTheme.teal),
                      ),
                    ),
                    const Spacer(),
                    // Search field only in Store tab
                    if (_tabController.index == 0 && !showGameBoard)
                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search apps',
                            isDense: true,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Main content
              Expanded(
                child: showGameBoard
                    ? GameBoardView(
                        gameId: selectedGameId!,
                        isDark: isDark,
                        onClose: () => appModel.selectGame(null),
                      )
                    : IndexedStack(
                        index: _tabController.index,
                        children: [
                          // Store Tab - with grid layout for wide screens
                          _buildStoreTabWide(appModel, isDark),
                          
                          // Library Tab - with grid layout for wide screens
                          _buildLibraryTab(context, appModel, isSmallScreen),
                        ],
                      ),
              ),
              
              // Status bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.black : AppTheme.lightSurface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      appModel.statusMessage,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    if (appModel.isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStoreTabWide(AppModel appModel, bool isDark) {
    if (appModel.isLoading && appModel.apps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final filteredApps = appModel.getFilteredApps(searchQuery);
    
    if (filteredApps.isEmpty) {
      return EmptyStateMessage(
        icon: Icons.search_off,
        title: appModel.selectedTags.isEmpty && appModel.selectedCategory == 'all' 
            ? 'No apps found' 
            : 'No matching apps found',
        subtitle: appModel.selectedTags.isEmpty && appModel.selectedCategory == 'all'
            ? 'Try adjusting your search query'
            : 'Try changing your category or tag filters',
        isDark: isDark,
      );
    }
    
    // Welcome landing section
    if (_isFirstLoad && appModel.selectedCategory == 'all' && searchQuery.isEmpty && appModel.selectedTags.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Card(
              elevation: isDark ? 4 : 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                      ? [AppTheme.darkGrey, AppTheme.black] 
                      : [Colors.white, Colors.grey.shade50],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Innova Launcher',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.lightText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your one-stop solution for Python apps and games',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeatureItem(
                            isDark,
                            Icons.category,
                            'Browse Categories',
                            'Explore a variety of Python apps organized by category',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFeatureItem(
                            isDark,
                            Icons.install_desktop,
                            'Simple Installation',
                            'Install and manage Python apps with a single click',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFeatureItem(
                            isDark,
                            Icons.tag,
                            'Filter by Tags',
                            'Find apps matching your interests with tag filtering',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Featured apps section
            Text(
              'Featured Apps',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 16),
            
            // Continue with the grid of apps
            _buildAppGrid(filteredApps, appModel, isDark),
          ],
        ),
      );
    }
    
    // Regular app grid without welcome landing
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildAppGrid(filteredApps, appModel, isDark),
    );
  }
  
  Widget _buildFeatureItem(bool isDark, IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 32,
            color: isDark ? AppTheme.pink : AppTheme.blue,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppGrid(List<MapEntry<String, dynamic>> apps, AppModel appModel, bool isDark) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        mainAxisExtent: 250,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      shrinkWrap: true,
      physics: _isFirstLoad && appModel.selectedCategory == 'all' && searchQuery.isEmpty && appModel.selectedTags.isEmpty
          ? NeverScrollableScrollPhysics() // For the welcome page, parent ScrollView handles scrolling
          : null,
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final entry = apps[index];
        final appName = entry.key;
        final appInfo = entry.value;
        final isInstalled = appModel.installedApps.contains(appName);
        final category = appModel.getCategoryById(appInfo['category'] as String? ?? 'utilities');
        
        // Use a staggered animation delay based on index
        final staggerDelay = Duration(milliseconds: 50 * (index % 10));
        
        return FutureBuilder(
          future: Future.delayed(staggerDelay, () => true),
          builder: (context, snapshot) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: snapshot.data == true ? 1.0 : 0.5,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 500),
                offset: snapshot.data == true ? Offset.zero : const Offset(0, 0.05),
                child: Card(
                  elevation: isDark ? 4 : 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: category.color.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: category.color.withOpacity(0.6),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                category.icon,
                                color: category.color,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: category.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          appInfo['description'] ?? 'No description',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        if (appInfo['tags'] != null)
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: (appInfo['tags'] as List).take(3).map((tag) {
                              return Chip(
                                label: Text(
                                  tag.toString(),
                                  style: TextStyle(fontSize: 10),
                                ),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (isInstalled)
                              TextButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Confirm Uninstall'),
                                      content: Text('Are you sure you want to uninstall $appName?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            appModel.uninstallApp(appName);
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: Text('Uninstall'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Uninstall'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (isInstalled) {
                                  appModel.launchApp(appName);
                                } else {
                                  appModel.installApp(appName);
                                }
                              },
                              icon: Icon(isInstalled ? Icons.play_arrow : Icons.download, size: 16),
                              label: Text(isInstalled ? 'Launch' : 'Install'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isInstalled 
                                    ? Colors.green 
                                    : (isDark ? AppTheme.pink : AppTheme.blue),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategorySelector(AppModel appModel, bool isDark, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 80 : 100,
      color: isDark ? AppTheme.black : AppTheme.lightSurface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: appModel.categories.length,
        itemBuilder: (context, index) {
          final category = appModel.categories[index];
          final isSelected = category.id == appModel.selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: isSelected 
                      ? category.color.withOpacity(isDark ? 0.8 : 0.6)
                      : (isDark ? Colors.black26 : Colors.white70),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => appModel.setCategory(category.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: isSmallScreen ? 50 : 60,
                      height: isSmallScreen ? 50 : 60,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected 
                              ? category.color 
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        category.icon,
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.white54 : Colors.black54),
                        size: isSmallScreen ? 24 : 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.name,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white54 : Colors.black54),
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTagsFilter(AppModel appModel, bool isDark, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter by Tags',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              if (appModel.selectedTags.isNotEmpty)
                TextButton(
                  onPressed: appModel.clearTags,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                    ),
                  ),
                )
            ],
          ),
        ),
        Container(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: appModel.availableTags.length,
            itemBuilder: (context, index) {
              final tag = appModel.availableTags[index];
              final isSelected = appModel.selectedTags.contains(tag);
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => appModel.toggleTag(tag),
                  checkmarkColor: Colors.white,
                  selectedColor: AppTheme.teal,
                  backgroundColor: isDark ? Colors.black26 : Colors.white70,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoreTab(BuildContext context, AppModel appModel, bool isSmallScreen) {
    final isDark = appModel.isDarkMode;
    final padding = EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 8.0 : 16.0, 
      vertical: 8.0
    );
    
    if (appModel.isLoading && appModel.apps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final filteredApps = appModel.getFilteredApps(searchQuery);
    
    if (filteredApps.isEmpty) {
      return EmptyStateMessage(
        icon: Icons.search_off,
        title: appModel.selectedTags.isEmpty && appModel.selectedCategory == 'all' 
            ? 'No apps found' 
            : 'No matching apps found',
        subtitle: appModel.selectedTags.isEmpty && appModel.selectedCategory == 'all'
            ? 'Try adjusting your search query'
            : 'Try changing your category or tag filters',
        isDark: isDark,
      );
    }
    
    return ListView.builder(
      padding: padding,
      itemCount: filteredApps.length,
      itemBuilder: (context, index) {
        final entry = filteredApps[index];
        final appName = entry.key;
        final appInfo = entry.value;
        final isInstalled = appModel.installedApps.contains(appName);
        final category = appModel.getCategoryById(appInfo['category'] as String? ?? 'utilities');
        
        return AppCard(
          appName: appName,
          appInfo: appInfo,
          category: category,
          isInstalled: isInstalled,
          onInstall: appModel.installApp,
          onLaunch: appModel.launchApp,
          onUninstall: appModel.uninstallApp,
          isDark: isDark,
          isCompact: isSmallScreen,
          index: index,
        );
      },
    );
  }

  Widget _buildLibraryTab(BuildContext context, AppModel appModel, bool isSmallScreen) {
    final theme = Theme.of(context);
    final isDark = appModel.isDarkMode;
    
    if (appModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    final filteredApps = appModel.installedApps
      .where((app) {
        final appData = appModel.getInstalledAppData(app);
        if (appData == null) return false;
        
        final name = appData['name']?.toString().toLowerCase() ?? '';
        final description = appData['description']?.toString().toLowerCase() ?? '';
        final author = appData['author']?.toString().toLowerCase() ?? '';
        
        if (searchQuery.isNotEmpty) {
          return name.contains(searchQuery) || 
                 description.contains(searchQuery) || 
                 author.contains(searchQuery);
        }
        
        if (appModel.selectedCategory != 'all') {
          final category = appData['category']?.toString() ?? '';
          return category == appModel.selectedCategory;
        }
        
        return true;
      })
      .toList();
    
    if (filteredApps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apps_outlined,
              size: 60,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            const SizedBox(height: 20),
            Text(
              appModel.installedApps.isEmpty
                  ? 'Your library is empty'
                  : 'No games match your search',
              style: TextStyle(
                fontSize: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              appModel.installedApps.isEmpty
                  ? 'Browse the store to find apps to install'
                  : 'Try a different search or category',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
            if (appModel.installedApps.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  icon: const Icon(Icons.store),
                  label: const Text('Go to store'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.teal : AppTheme.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20, 
                      vertical: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate number of columns based on available width
        final double itemWidth = 220;
        final int crossAxisCount = max(1, (constraints.maxWidth / itemWidth).floor());
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredApps.length,
          itemBuilder: (context, index) {
            final app = filteredApps[index];
            final appData = appModel.getInstalledAppData(app);
            if (appData == null) return const SizedBox();
            
            final name = appData['name'] ?? app;
            final description = appData['description'] ?? '';
            final author = appData['author'] ?? '';
            final version = appData['version'] ?? '';
            
            return InkWell(
              onTap: () => appModel.selectGame(app),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark 
                              ? [AppTheme.teal.withOpacity(0.7), AppTheme.darkGrey]
                              : [AppTheme.blue.withOpacity(0.7), AppTheme.blue.withOpacity(0.1)],
                        ),
                      ),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (author.isNotEmpty)
                            Text(
                              'by $author',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    
                    // App content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (description.isNotEmpty) ...[
                              Expanded(
                                child: Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 4,
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 12),
                            
                            // Control row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Version
                                if (version.isNotEmpty)
                                  Text(
                                    'v$version',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white54 : Colors.black45,
                                    ),
                                  ),
                                  
                                const Spacer(),
                                
                                // Action buttons
                                ElevatedButton.icon(
                                  onPressed: () => appModel.launchApp(app),
                                  icon: const Icon(Icons.play_arrow, size: 16),
                                  label: const Text('Play'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? AppTheme.teal : AppTheme.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10, 
                                      vertical: 0,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                
                                if (appModel.hasModsForGame(app)) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(
                                      Icons.extension,
                                      size: 16,
                                      color: isDark ? AppTheme.pink : AppTheme.purple,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => appModel.selectGame(app),
                                    tooltip: 'Manage mods',
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLibraryTabWide(AppModel appModel, bool isDark) {
    if (appModel.isLoading && appModel.installedApps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final filteredApps = appModel.getFilteredInstalledApps();
    
    if (appModel.installedApps.isEmpty) {
      return EmptyStateMessage(
        icon: Icons.apps,
        title: 'No apps installed yet',
        subtitle: 'Go to the Store tab to install apps',
        isDark: isDark,
      );
    }
    
    if (filteredApps.isEmpty) {
      return EmptyStateMessage(
        icon: Icons.filter_list_off,
        title: 'No matching installed apps',
        subtitle: 'Try changing your category filter',
        isDark: isDark,
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildAppGrid(filteredApps, appModel, isDark),
    );
  }
} 