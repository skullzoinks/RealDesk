import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../app/routes.dart';
import '../../features/xbox/models/xbox_game.dart';
import '../../features/xbox/services/xbox_game_service.dart';
import '../widgets/switch_game_card.dart';
import '../widgets/system_icon_button.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  final _service = XboxGameService.instance;
  final _logger = Logger();
  final PageController _pageController = PageController(viewportFraction: 0.25);

  List<XboxGame> _games = const [];
  bool _isLoading = false;
  String? _error;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshGames();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshGames({bool force = false}) async {
    setState(() {
      _isLoading = true;
      if (force) {
        _error = null;
      }
    });

    try {
      final games = await _service.fetchGames(forceRefresh: force);
      if (mounted) {
        setState(() {
          _games = games;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _logger.w('Failed to load games', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            color: theme.scaffoldBackgroundColor,
          ),
          
          // Content
          Column(
            children: [
              // Top Bar
              _buildTopBar(),
              
              const Spacer(),
              
              // Game Carousel
              if (_isLoading && _games.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (_games.isEmpty)
                _buildEmptyState()
              else
                SizedBox(
                  height: 320,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _games.length,
                    onPageChanged: (index) {
                      setState(() => _focusedIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final game = _games[index];
                      final isFocused = index == _focusedIndex;
                      return Center(
                        child: SwitchGameCard(
                          game: game,
                          isFocused: isFocused,
                          width: isFocused ? 320 : 260,
                          height: isFocused ? 180 : 146,
                          onTap: () {
                            if (index != _focusedIndex) {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutQuad,
                              );
                            } else {
                              // TODO: Launch game or show details
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              
              const Spacer(),
              
              // System Icons Row
              _buildSystemRow(),
              
              const SizedBox(height: 48),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: const DecorationImage(
                image: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Felix'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Spacer(),
          // Status Icons
          const Icon(Icons.wifi, color: Colors.white70),
          const SizedBox(width: 16),
          const Text('12:00', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          const Icon(Icons.battery_full, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildSystemRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SystemIconButton(
          icon: Icons.newspaper,
          label: 'News',
          color: Colors.redAccent,
          onTap: () {},
        ),
        const SizedBox(width: 32),
        SystemIconButton(
          icon: Icons.shopping_bag,
          label: 'eShop',
          color: Colors.orangeAccent,
          onTap: () {},
        ),
        const SizedBox(width: 32),
        SystemIconButton(
          icon: Icons.photo_library,
          label: 'Album',
          color: Colors.blueAccent,
          onTap: () {},
        ),
        const SizedBox(width: 32),
        SystemIconButton(
          icon: Icons.gamepad,
          label: 'Controllers',
          color: Colors.grey,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.connect),
        ),
        const SizedBox(width: 32),
        SystemIconButton(
          icon: Icons.settings,
          label: 'Settings',
          color: Colors.grey,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
        ),
        const SizedBox(width: 32),
        SystemIconButton(
          icon: Icons.power_settings_new,
          label: 'Power',
          color: Colors.grey,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            'No games found',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _refreshGames(force: true),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
