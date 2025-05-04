import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'model.dart';
import 'theme.dart';
import 'dart:math';

class GradientHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool isDark;
  final double? height;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.isDark,
    this.height,
  });

  @override
  State<GradientHeader> createState() => _GradientHeaderState();
}

class _GradientHeaderState extends State<GradientHeader> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isVerySmallScreen = screenSize.width < 400 || (widget.height != null && widget.height! < 100);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: widget.height,
      constraints: BoxConstraints(
        minHeight: isVerySmallScreen ? 60 : (isSmallScreen ? 80 : 120),
        maxHeight: isVerySmallScreen ? 90 : (isSmallScreen ? 120 : 160),
      ),
      padding: EdgeInsets.symmetric(
        vertical: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 20), 
        horizontal: isSmallScreen ? 12 : 20
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient(isDark: widget.isDark),
      ),
      child: Stack(
        children: [
          // Animated background particles
          ...List.generate(10, (index) {
            final rng = Random(index);
            final size = rng.nextDouble() * 8 + 4;
            final left = rng.nextDouble() * screenSize.width;
            final top = rng.nextDouble() * (widget.height ?? 120);
            final opacity = rng.nextDouble() * 0.1 + 0.05;
            
            return Positioned(
              left: left,
              top: top,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      sin(_controller.value * 2 * pi + index) * 10,
                      cos(_controller.value * 2 * pi + index) * 5,
                    ),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 1000),
                      opacity: widget.isDark ? opacity * 2 : opacity,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(_glowAnimation.value * 0.3),
                              blurRadius: 10,
                              spreadRadius: _glowAnimation.value * 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          
          // Main content
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // If very limited space, use more compact layout and smaller or no subtitle
                if (constraints.maxHeight < 85) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  if (widget.isDark)
                                    BoxShadow(
                                      color: Colors.white.withOpacity(_glowAnimation.value * 0.1),
                                      blurRadius: 15,
                                      spreadRadius: 5,
                                    ),
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVerySmallScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Segoe UI',
                              shadows: widget.isDark ? [
                                const Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 5.0,
                                  color: Color.fromARGB(100, 0, 0, 0),
                                ),
                              ] : null,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      if (widget.subtitle != null && constraints.maxHeight >= 70)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              widget.subtitle!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  );
                }
                
                // Standard vertical layout for normal space
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedTitle(isSmallScreen, isVerySmallScreen),
                    if (widget.subtitle != null)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.7 + _glowAnimation.value * 0.3,
                            child: child,
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.only(top: isSmallScreen ? 6 : 12),
                          child: Text(
                            widget.subtitle!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16),
                              shadows: widget.isDark ? [
                                const Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3.0,
                                  color: Color.fromARGB(80, 0, 0, 0),
                                ),
                              ] : null,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: isVerySmallScreen ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTitle(bool isSmallScreen, bool isVerySmallScreen) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isDark ? 1.0 + (_glowAnimation.value * 0.03) : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        if (widget.isDark)
                          BoxShadow(
                            color: Colors.white.withOpacity(_glowAnimation.value * 0.15),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isVerySmallScreen ? 18 : (isSmallScreen ? 22 : 32),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Segoe UI',
                  shadows: widget.isDark ? [
                    Shadow(
                      offset: const Offset(0, 2),
                      blurRadius: 5.0,
                      color: Color.fromARGB(100, 0, 0, 0),
                    ),
                    Shadow(
                      offset: const Offset(0, 0),
                      blurRadius: 15.0,
                      color: AppTheme.pink.withOpacity(0.3),
                    ),
                  ] : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}

class StatusNotification extends StatelessWidget {
  final bool isPython;
  final bool isInstalled;
  final VoidCallback onInstall;
  final bool isDark;
  final bool isCompact;
  final bool isInstalling;

  const StatusNotification({
    super.key,
    required this.isPython,
    required this.isInstalled,
    required this.onInstall,
    required this.isDark,
    this.isCompact = false,
    this.isInstalling = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isPython 
        ? (isDark ? AppTheme.pink.withOpacity(0.15) : AppTheme.pink.withOpacity(0.1))
        : (isDark ? AppTheme.cyan.withOpacity(0.15) : AppTheme.cyan.withOpacity(0.1));
    
    final Color iconColor = isPython ? AppTheme.pink : AppTheme.cyan;
    final Color textColor = isDark ? Colors.white : AppTheme.lightText;
    
    String title = isPython
        ? 'Python is required but not installed'
        : 'Pygame is required for games but not installed';
    
    final String buttonText = isPython ? 'Install Python' : 'Install Pygame';
    String installingText = isPython ? 'Installing Python...' : 'Installing Pygame...';
    
    // Platform-specific messages
    if (isPython) {
      if (Platform.isMacOS) {
        title = 'Python 3 is required (will install via Homebrew)';
        installingText = 'Installing Python 3 via Homebrew...';
      } else if (Platform.isWindows) {
        title = 'Python is required (will download installer)';
        installingText = 'Setting up Python installation...';
      } else if (Platform.isLinux) {
        title = 'Python 3 is required (will use system package manager)';
        installingText = 'Installing Python via package manager...';
      }
    } else {
      if (Platform.isMacOS) {
        title = 'Pygame is required (will install dependencies via Homebrew)';
        installingText = 'Installing Pygame and dependencies...';
      } else if (Platform.isWindows) {
        title = 'Pygame is required (will install via pip)';
        installingText = 'Installing Pygame via pip...';
      } else if (Platform.isLinux) {
        title = 'Pygame is required (will install dependencies)';
        installingText = 'Installing Pygame and dependencies...';
      }
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16, 
        vertical: isCompact ? 8 : 12
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        border: Border.all(
          color: isPython 
              ? AppTheme.pink.withOpacity(isDark ? 0.3 : 0.2)
              : AppTheme.cyan.withOpacity(isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          isInstalling
              ? SizedBox(
                  width: isCompact ? 18 : 24,
                  height: isCompact ? 18 : 24,
                  child: CircularProgressIndicator(
                    strokeWidth: isCompact ? 1.5 : 2,
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  ),
                )
              : Icon(
                  isPython ? Icons.warning : Icons.info_outline, 
                  color: iconColor,
                  size: isCompact ? 18 : 24,
                ),
          SizedBox(width: isCompact ? 8 : 12),
          Expanded(
            child: Text(
              isInstalling ? installingText : title,
              style: TextStyle(
                color: isDark ? iconColor : AppTheme.lightText, 
                fontWeight: FontWeight.w500,
                fontSize: isCompact ? 13 : 14,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 6 : 8),
          isInstalling
              ? const SizedBox() // No button while installing
              : ElevatedButton(
                  onPressed: onInstall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    padding: isCompact 
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
                      : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 12 : 14,
                    ),
                  ),
                  child: Text(buttonText),
                ),
        ],
      ),
    );
  }
}

class AppCard extends StatefulWidget {
  final String appName;
  final Map<String, dynamic> appInfo;
  final Category category;
  final bool isInstalled;
  final Function(String) onInstall;
  final Function(String) onLaunch;
  final Function(String) onUninstall;
  final bool isDark;
  final bool isCompact;
  final int index;

  const AppCard({
    super.key,
    required this.appName,
    required this.appInfo,
    required this.category,
    required this.isInstalled,
    required this.onInstall,
    required this.onLaunch,
    required this.onUninstall,
    required this.isDark,
    this.isCompact = false,
    this.index = 0,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    
    // Create animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
    
    _opacityAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller, 
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    // Add a small delay based on index for staggered animation
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : AppTheme.lightText;
    final secondaryTextColor = widget.isDark 
        ? Colors.white.withOpacity(0.8) 
        : AppTheme.lightText.withOpacity(0.7);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _isHovering ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() { 
          _isHovering = true;
          _controller.forward();
        }),
        onExit: (_) => setState(() { 
          _isHovering = false;
          _controller.reverse();
        }),
        child: Card(
          elevation: widget.isDark ? (_isHovering ? 8 : 4) : (_isHovering ? 4 : 2),
          margin: EdgeInsets.only(bottom: widget.isCompact ? 12 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.isCompact ? 8 : 12),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
            child: widget.isCompact 
                ? _buildCompactLayout(context, textColor, secondaryTextColor)
                : _buildStandardLayout(context, textColor, secondaryTextColor),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardLayout(BuildContext context, Color textColor, Color secondaryTextColor) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 500;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category circle indicator
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                color: widget.category.color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.category.color.withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: Icon(
                widget.category.icon,
                color: widget.category.color,
                size: 14,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.appName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.category.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.category.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.appInfo['description'] ?? 'No description',
                    style: TextStyle(
                      color: secondaryTextColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.appInfo['tags'] != null) _buildTags(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (!isNarrow)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (widget.isInstalled) {
                        widget.onLaunch(widget.appName);
                      } else {
                        widget.onInstall(widget.appName);
                      }
                    },
                    icon: Icon(widget.isInstalled ? Icons.play_arrow : Icons.download, size: 16),
                    label: Text(widget.isInstalled ? 'Launch' : 'Install', 
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isInstalled 
                          ? Colors.green 
                          : (widget.isDark ? AppTheme.pink : AppTheme.blue),
                      elevation: widget.isDark ? 2 : 1,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  if (widget.isInstalled)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: () => _confirmUninstall(context),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Uninstall', style: TextStyle(fontSize: 14)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        // Add buttons at the bottom for narrow screens
        if (isNarrow)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.isInstalled)
                  TextButton.icon(
                    onPressed: () => _confirmUninstall(context),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Uninstall', style: TextStyle(fontSize: 14)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (widget.isInstalled) {
                      widget.onLaunch(widget.appName);
                    } else {
                      widget.onInstall(widget.appName);
                    }
                  },
                  icon: Icon(widget.isInstalled ? Icons.play_arrow : Icons.download, size: 16),
                  label: Text(widget.isInstalled ? 'Launch' : 'Install',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isInstalled 
                        ? Colors.green 
                        : (widget.isDark ? AppTheme.pink : AppTheme.blue),
                    elevation: widget.isDark ? 2 : 1,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context, Color textColor, Color secondaryTextColor) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isVeryNarrow = screenWidth < 360;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Category circle indicator
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: widget.category.color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.category.color.withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: Icon(
                widget.category.icon,
                color: widget.category.color,
                size: 12,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    widget.category.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.category.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          widget.appInfo['description'] ?? 'No description',
          style: TextStyle(
            color: secondaryTextColor,
            height: 1.3,
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        if (widget.appInfo['tags'] != null) _buildTags(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.isInstalled && !isVeryNarrow)
              TextButton.icon(
                onPressed: () => _confirmUninstall(context),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Uninstall', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            // For very narrow screens, show just icon
            if (widget.isInstalled && isVeryNarrow)
              IconButton(
                onPressed: () => _confirmUninstall(context),
                icon: const Icon(Icons.delete, size: 18),
                color: Colors.red,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                tooltip: 'Uninstall',
              ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.isInstalled) {
                  widget.onLaunch(widget.appName);
                } else {
                  widget.onInstall(widget.appName);
                }
              },
              icon: Icon(
                widget.isInstalled ? Icons.play_arrow : Icons.download, 
                size: 16
              ),
              label: Text(
                isVeryNarrow
                    ? (widget.isInstalled ? 'Run' : 'Get')
                    : (widget.isInstalled ? 'Launch' : 'Install'),
                style: TextStyle(fontSize: 11)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isInstalled 
                    ? Colors.green 
                    : (widget.isDark ? AppTheme.pink : AppTheme.blue),
                elevation: widget.isDark ? 2 : 1,
                padding: EdgeInsets.symmetric(
                  horizontal: isVeryNarrow ? 6 : 8, 
                  vertical: 4
                ),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTags() {
    final tags = (widget.appInfo['tags'] as List<dynamic>).map((tag) => tag.toString()).toList();
    
    // Sort tags by length to display shorter tags first
    tags.sort((a, b) => a.length.compareTo(b.length));
    
    return Wrap(
      spacing: widget.isCompact ? 4 : 6,
      runSpacing: widget.isCompact ? 4 : 6,
      children: tags.map((tag) {
        return Chip(
          label: Text(
            tag,
            style: TextStyle(fontSize: widget.isCompact ? 10 : 12),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          labelPadding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 6 : 8,
            vertical: widget.isCompact ? 0 : 1,
          ),
          backgroundColor: _getTagColor(tag),
        );
      }).toList(),
    );
  }
  
  Color _getTagColor(String tag) {
    // Generate consistent colors based on tag name
    final tagHash = tag.codeUnits.fold(0, (prev, curr) => prev + curr);
    
    // Predefined colors for common tags
    if (tag.toLowerCase().contains('game')) {
      return Colors.purple.withOpacity(0.2);
    } else if (tag.toLowerCase().contains('education')) {
      return Colors.orange.withOpacity(0.2);
    } else if (tag.toLowerCase().contains('media')) {
      return Colors.red.withOpacity(0.2);
    } else if (tag.toLowerCase().contains('utility')) {
      return Colors.green.withOpacity(0.2);
    } else if (tag.toLowerCase().contains('dev')) {
      return Colors.indigo.withOpacity(0.2);
    }
    
    // Generate color based on tag hash
    final baseColors = [
      Colors.blue, Colors.teal, Colors.amber, 
      Colors.pink, Colors.green, Colors.deepPurple
    ];
    
    final selectedColor = baseColors[tagHash % baseColors.length];
    return selectedColor.withOpacity(0.2);
  }

  void _confirmUninstall(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDark ? AppTheme.darkGrey : AppTheme.lightSurface,
        title: Text(
          'Confirm Uninstall',
          style: TextStyle(
            color: widget.isDark ? Colors.white : AppTheme.lightText,
          ),
        ),
        content: Text(
          'Are you sure you want to uninstall ${widget.appName}?',
          style: TextStyle(
            color: widget.isDark 
                ? Colors.white.withOpacity(0.9) 
                : AppTheme.lightText.withOpacity(0.9),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onUninstall(widget.appName);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }
}

class StatusBar extends StatefulWidget {
  final bool isLoading;
  final String statusMessage;
  final double progress;
  final bool isDark;

  const StatusBar({
    super.key,
    required this.isLoading,
    required this.statusMessage,
    required this.progress,
    required this.isDark,
  });

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  String _previousStatus = "Ready";
  String _currentStatus = "Ready";
  bool _transitioning = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.statusMessage;
    _previousStatus = widget.statusMessage;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(begin: 0, end: widget.progress / 100).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
    
    _animationController.value = widget.progress / 100;
  }
  
  @override
  void didUpdateWidget(StatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate progress changes
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress / 100,
        end: widget.progress / 100
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
      );
      
      _animationController.forward(from: 0);
    }
    
    // Animate status message changes
    if (oldWidget.statusMessage != widget.statusMessage) {
      setState(() {
        _previousStatus = oldWidget.statusMessage;
        _currentStatus = widget.statusMessage;
        _transitioning = true;
      });
      
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            _transitioning = false;
          });
        }
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDark 
        ? Colors.black.withOpacity(0.4) 
        : Colors.black.withOpacity(0.05);
    
    final textColor = widget.isDark 
        ? Colors.white.withOpacity(0.9) 
        : AppTheme.lightText.withOpacity(0.9);
    
    final accentColor = widget.isDark ? AppTheme.pink : AppTheme.blue;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          if (!widget.isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (widget.isLoading)
                AnimatedRotation(
                  turns: widget.isLoading ? 1.0 : 0,
                  duration: const Duration(seconds: 2),
                  child: SizedBox(
                    width: isSmallScreen ? 14 : 16,
                    height: isSmallScreen ? 14 : 16,
                    child: CircularProgressIndicator(
                      strokeWidth: isSmallScreen ? 1.5 : 2,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                )
              else
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: child,
                    );
                  },
                  child: Icon(
                    Icons.info_outline, 
                    size: isSmallScreen ? 14 : 16, 
                    color: accentColor
                  ),
                ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    widget.statusMessage,
                    key: ValueKey<String>(widget.statusMessage),
                    style: TextStyle(
                      color: textColor,
                      fontSize: isSmallScreen ? 12 : 14
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.isLoading)
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 6 : 8),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: widget.progress > 0 ? _progressAnimation.value : null,
                    backgroundColor: widget.isDark 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const EmptyStateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark 
        ? Colors.white.withOpacity(0.3)
        : Colors.black.withOpacity(0.2);
        
    final titleColor = isDark 
        ? Colors.white.withOpacity(0.7)
        : AppTheme.lightText.withOpacity(0.8);
    
    final subtitleColor = isDark 
        ? Colors.white.withOpacity(0.5)
        : AppTheme.lightText.withOpacity(0.6);
    
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // If space is very limited, use SingleChildScrollView
        if (constraints.maxHeight < 150) {
          return SingleChildScrollView(
            child: _buildContent(
              iconColor, 
              titleColor, 
              subtitleColor, 
              isSmallScreen
            ),
          );
        }
        
        // Otherwise use normal centered content
        return Center(
          child: _buildContent(
            iconColor, 
            titleColor, 
            subtitleColor, 
            isSmallScreen
          ),
        );
      }
    );
  }
  
  Widget _buildContent(
    Color iconColor, 
    Color titleColor, 
    Color subtitleColor, 
    bool isSmallScreen
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isSmallScreen ? 48 : 64,
          color: iconColor,
        ),
        SizedBox(height: isSmallScreen ? 16 : 24),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 24 : 32
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor,
              fontSize: isSmallScreen ? 14 : 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class GameBoardView extends StatefulWidget {
  final String gameId;
  final bool isDark;
  final VoidCallback onClose;

  const GameBoardView({
    Key? key,
    required this.gameId,
    required this.isDark,
    required this.onClose,
  }) : super(key: key);

  @override
  _GameBoardViewState createState() => _GameBoardViewState();
}

class _GameBoardViewState extends State<GameBoardView> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }
  
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final appModel = AppModel.of(context);
    final game = appModel.getInstalledAppData(widget.gameId);
    if (game == null) {
      return Center(
        child: Text('Game not found'),
      );
    }
    
    final isInstalled = appModel.isAppInstalled(widget.gameId);
    final hasMods = appModel.hasModsForGame(widget.gameId);
    final mods = appModel.getModsForGame(widget.gameId);
    final hasEnabledMods = mods.any((mod) => mod.enabled);
    
    // Get game data
    final name = game['name'] ?? widget.gameId;
    final description = game['description'] ?? '';
    final author = game['author'] ?? 'Unknown';
    final version = game['version'] ?? '';
    
    return FadeTransition(
      opacity: _animation,
      child: Container(
        color: widget.isDark 
            ? AppTheme.darkGrey 
            : Colors.grey[100],
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isDark 
                      ? [AppTheme.teal.withOpacity(0.3), AppTheme.darkGrey] 
                      : [AppTheme.teal.withOpacity(0.2), Colors.white],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: widget.onClose,
                        tooltip: 'Back to games',
                      ),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 56, right: 16, bottom: 8),
                    child: Text(
                      'by $author ${version.isNotEmpty ? "• v$version" : ""}',
                      style: TextStyle(
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    if (description.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? AppTheme.teal : AppTheme.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.isDark ? Colors.black26 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: widget.isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Launch buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isInstalled 
                                ? () => appModel.launchApp(widget.gameId)
                                : null,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: widget.isDark ? AppTheme.teal : AppTheme.blue,
                            ),
                          ),
                        ),
                        if (hasMods) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isInstalled && hasEnabledMods
                                  ? () => appModel.launchAppWithMods(widget.gameId)
                                  : null,
                              icon: const Icon(Icons.extension),
                              label: const Text('Play with Mods'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: widget.isDark ? AppTheme.pink : AppTheme.purple,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Mods section
                    if (hasMods) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Mods',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.isDark ? AppTheme.pink : AppTheme.purple,
                            ),
                          ),
                          if (appModel.isLoadingMods)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...mods.map((mod) => _buildModTile(appModel, mod)),
                    ] else ...[
                      // No mods available
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.isDark ? Colors.black26 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.extension_off,
                              size: 48,
                              color: widget.isDark ? Colors.white30 : Colors.black26,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No mods available for this game',
                              style: TextStyle(
                                fontSize: 16,
                                color: widget.isDark ? Colors.white70 : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModTile(AppModel appModel, GameMod mod) {
    final bool isInstalled = mod.downloadUrl == null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.black26 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: mod.enabled 
              ? (widget.isDark ? AppTheme.pink.withOpacity(0.5) : AppTheme.purple.withOpacity(0.5))
              : (widget.isDark ? Colors.white10 : Colors.black12),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          listTileTheme: ListTileThemeData(
            dense: true,
            horizontalTitleGap: 8,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ),
        child: ExpansionTile(
          title: Text(
            mod.name,
            style: TextStyle(
              fontWeight: mod.enabled ? FontWeight.bold : FontWeight.normal,
              color: mod.enabled
                  ? (widget.isDark ? AppTheme.pink : AppTheme.purple) 
                  : null,
            ),
          ),
          subtitle: mod.version != null && mod.version!.isNotEmpty || mod.author != null && mod.author!.isNotEmpty
              ? Text(
                  [
                    if (mod.version != null && mod.version!.isNotEmpty) 'v${mod.version}',
                    if (mod.author != null && mod.author!.isNotEmpty) 'by ${mod.author}',
                  ].join(' • '),
                  style: const TextStyle(fontSize: 12),
                )
              : null,
          leading: Icon(
            mod.enabled ? Icons.extension : Icons.extension_outlined,
            color: mod.enabled
                ? (widget.isDark ? AppTheme.pink : AppTheme.purple)
                : null,
          ),
          trailing: Switch(
            value: mod.enabled,
            onChanged: (value) {
              appModel.toggleMod(widget.gameId, mod.id, value);
            },
            activeColor: widget.isDark ? AppTheme.pink : AppTheme.purple,
          ),
          children: [
            if (mod.description != null && mod.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  mod.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            
            // Install button if not installed and has download URL
            if (!isInstalled && mod.downloadUrl != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ElevatedButton.icon(
                  onPressed: () => appModel.installMod(widget.gameId, mod.id),
                  icon: const Icon(Icons.download),
                  label: const Text('Install Mod'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isDark ? AppTheme.teal : AppTheme.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
