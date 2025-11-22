import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../app/routes.dart';
import '../../features/xbox/models/xbox_game.dart';
import '../../features/xbox/services/xbox_game_service.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  final _service = XboxGameService.instance;
  final _logger = Logger();

  List<XboxGame> _games = const [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshGames();
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
      _logger.w('Failed to load Xbox games', error: e, stackTrace: stackTrace);
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B5F17), Color(0xFF107C10), Color(0xFF0E4410)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return RefreshIndicator(
                onRefresh: () => _refreshGames(force: true),
                color: Colors.white,
                backgroundColor: const Color(0xFF0D2E0D),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeroSection(context, width),
                    ),
                    if (_error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: _buildErrorBanner(context),
                        ),
                      ),
                    if (_isLoading && _games.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildLoadingState(),
                      )
                    else if (_games.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context),
                      )
                    else
                      _buildGameGrid(width),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 32),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, double width) {
    final isWide = width >= 900;
    final highlightGames = _games.take(3).toList();
    final textTheme = Theme.of(context).textTheme;

    final headline = Text(
      'RealDesk 启动中心',
      style: textTheme.headlineMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );

    final subtitle = Text(
      '参考 Xbox 游戏浏览体验，为远程桌面增添一份娱乐灵感。'
      '快速浏览热门游戏风格，并在任意设备上连接远程主机。',
      style: textTheme.bodyLarge?.copyWith(
        color: Colors.white70,
        height: 1.5,
      ),
    );

    final actionButtons = Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F3B0F),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.connect),
          icon: const Icon(Icons.play_circle_fill),
          label: const Text('开始远程连接'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white70, width: 1.4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          onPressed: _isLoading ? null : () => _refreshGames(force: true),
          icon: const Icon(Icons.refresh),
          label: const Text('刷新游戏数据'),
        ),
      ],
    );

    final highlights = highlightGames.isEmpty
        ? const SizedBox.shrink()
        : Wrap(
            spacing: 16,
            runSpacing: 16,
            children: highlightGames.map(_buildHighlightCard).toList(),
          );

    final heroIllustration = _buildHeroIllustration(width);

    final content = <Widget>[
      headline,
      const SizedBox(height: 16),
      subtitle,
      const SizedBox(height: 24),
      actionButtons,
      const SizedBox(height: 32),
      highlights,
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 24,
        vertical: isWide ? 32 : 24,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: isWide
            ? Row(
                key: const ValueKey('wide-hero'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: content,
                    ),
                  ),
                  const SizedBox(width: 32),
                  SizedBox(width: width * 0.28, child: heroIllustration),
                ],
              )
            : Column(
                key: const ValueKey('compact-hero'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...content,
                  const SizedBox(height: 24),
                  heroIllustration,
                ],
              ),
      ),
    );
  }

  Widget _buildHeroIllustration(double width) {
    final height = width >= 900 ? 320.0 : 220.0;
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1C8C2E), Color(0xFF2DD14B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x60000000),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -40,
            child: Container(
              width: height * 0.9,
              height: height * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: height * 0.6,
              height: height * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.gamepad, color: Colors.white, size: 36),
                  SizedBox(height: 12),
                  Text(
                    '同步遥控 • 共享娱乐',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '浏览热度榜单，从容切换远程桌面，\n体验跨平台的游戏陪伴。',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard(XboxGame game) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            game.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            game.priceText ?? '暂未获取价格',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (game.platforms.isEmpty ? ['Xbox', 'PC'] : game.platforms)
                .take(3)
                .map(
                  (platform) => Chip(
                    label: Text(platform, style: const TextStyle(fontSize: 12)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  SliverPadding _buildGameGrid(double width) {
    final crossAxisCount = width >= 1440
        ? 4
        : width >= 1080
            ? 3
            : width >= 720
                ? 2
                : 1;
    final itemHeight = width >= 720 ? 280.0 : 240.0;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: crossAxisCount == 1
              ? 2.9
              : crossAxisCount == 2
                  ? 1.8
                  : 1.4,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final game = _games[index];
            return _GameCard(game: game, height: itemHeight);
          },
          childCount: _games.length,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 56, color: Colors.white70),
          const SizedBox(height: 16),
          Text(
            '暂时无法获取 Xbox 游戏列表',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            '请检查网络连接或稍后再试。',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F3B0F),
            ),
            onPressed: () => _refreshGames(force: true),
            icon: const Icon(Icons.refresh),
            label: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '数据拉取出现问题',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  _error ?? '未知错误',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => _refreshGames(force: true),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.height});

  final XboxGame game;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openStore(game.storeUri),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        game.priceText ?? '价格待定',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children:
                            (game.platforms.isEmpty ? ['Xbox'] : game.platforms)
                                .take(4)
                                .map(
                                  (platform) => Chip(
                                    label: Text(
                                      platform,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.18),
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (game.thumbnailUri == null) {
      return Container(
        height: height * 0.45,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A6B24), Color(0xFF0C3F0D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.videogame_asset, color: Colors.white54, size: 48),
        ),
      );
    }

    return SizedBox(
      height: height * 0.45,
      width: double.infinity,
      child: Image.network(
        game.thumbnailUri!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A6B24), Color(0xFF0C3F0D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child:
                  Icon(Icons.videogame_asset, color: Colors.white54, size: 48),
            ),
          );
        },
      ),
    );
  }

  void _openStore(String uri) {
    // Intentionally left as a no-op; shell launching will be wired in platform-specific layers.
  }
}
