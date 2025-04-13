// lib/screens/RecipeDetailScreen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/api_service.dart'; // ApiService'i import et

class RecipeDetailScreen extends StatefulWidget {
  final RecipeModel recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;
  bool _timerStarted = false;
  late int _initialDurationInSeconds;

  late bool _isLiked;
  bool _isLikeOperationLoading = false;
  final ApiService _apiService = ApiService();
  late int _currentLikeCount; // Like sayısını da state'de tutalım

  @override
  void initState() {
    super.initState();
    int cookingTimeMinutes = widget.recipe.cookingTimeInMinutes ?? 0;
    _initialDurationInSeconds =
        cookingTimeMinutes > 0 ? cookingTimeMinutes * 60 : 0;
    _remainingSeconds = _initialDurationInSeconds;
    // Başlangıç durumlarını widget'tan al
    _isLiked = widget.recipe.isLikedByCurrentUser;
    _currentLikeCount = widget.recipe.likeCount;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {/* ... (Zamanlayıcı kodu) ... */}
  void _pauseTimer() {/* ... (Zamanlayıcı kodu) ... */}
  void _resetTimer() {/* ... (Zamanlayıcı kodu) ... */}
  String _formatDuration(int totalSeconds) {
    /* ... (Zamanlayıcı kodu) ... */ return Duration(seconds: totalSeconds)
        .toString()
        .split('.')
        .first
        .padLeft(8, '0')
        .substring(3);
  }

  void _showTimerFinishedDialog() {/* ... (Zamanlayıcı kodu) ... */}

  Future<void> _toggleLike() async {
    if (_isLikeOperationLoading) return;
    setState(() {
      _isLikeOperationLoading = true;
    });

    try {
      if (_isLiked) {
        await _apiService.unlikeRecipe(widget.recipe.id);
        setState(() {
          _isLiked = false;
          _currentLikeCount--;
        }); // Sayıyı azalt
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Beğeni geri alındı.'),
            duration: Duration(seconds: 1),
          ));
      } else {
        await _apiService.likeRecipe(widget.recipe.id);
        setState(() {
          _isLiked = true;
          _currentLikeCount++;
        }); // Sayıyı artır
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Tarif beğenildi!'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.pinkAccent));
      }
      // Widget'ın orijinal verisini güncelleme (isteğe bağlı ama iyi pratik)
      widget.recipe.isLikedByCurrentUser = _isLiked;
      // widget.recipe.likeCount = _currentLikeCount; // likeCount final olmadığı için güncellenemez, bu yüzden state kullandık
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('İşlem başarısız: $e'), backgroundColor: Colors.red));
      // Başarısız olursa state'i geri alabiliriz (opsiyonel)
      // setState(() { _isLiked = !_isLiked; _currentLikeCount += _isLiked ? -1 : 1; });
    } finally {
      if (mounted) {
        setState(() {
          _isLikeOperationLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool showTimer = _initialDurationInSeconds > 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            stretch: true,
            backgroundColor: primaryColor,
            actions: [
              // Like Count Göstergesi
              Padding(
                padding: const EdgeInsets.only(
                    right: 0.0), // Butonla arasına boşluk koyma
                child: Center(
                    child: Text(_currentLikeCount.toString(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
              ),
              IconButton(
                icon: _isLikeOperationLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ))
                    : Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.white,
                      ),
                tooltip: _isLiked ? 'Beğeniyi Geri Al' : 'Beğen',
                onPressed: _toggleLike,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  (widget.recipe.videoUrl != null &&
                          widget.recipe.videoUrl!.isNotEmpty)
                      ? buildVideoPlayerPlaceholder(context, accentColor)
                      : Image.network(
                          widget.recipe.imageUrl,
                          fit: BoxFit.cover, /* ... */
                        ),
                  Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.6)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.5, 1.0]))),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
                  child: Text(widget.recipe.title,
                      style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: Colors.grey[850]),
                      textAlign: TextAlign.center)),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 16.0,
                  runSpacing: 16.0,
                  children: [
                    buildMacroInfo(
                        Icons.local_fire_department_outlined,
                        '${widget.recipe.calories ?? '?'}',
                        'kcal',
                        accentColor),
                    buildMacroInfo(
                        Icons.fitness_center_outlined,
                        '${widget.recipe.protein ?? '?'}',
                        'g Prot',
                        Colors.blueGrey.shade600),
                    buildMacroInfo(
                        Icons.spa_outlined,
                        '${widget.recipe.carbs ?? '?'}',
                        'g Karb',
                        Colors.orange.shade700),
                    buildMacroInfo(
                        Icons.opacity_outlined,
                        '${widget.recipe.fat ?? '?'}',
                        'g Yağ',
                        Colors.teal.shade600),
                  ],
                ),
              ),
              const Divider(
                  height: 24, thickness: 1, indent: 16, endIndent: 16),
              if (showTimer)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    children: [
                      buildSectionTitle('Pişirme Süresi Zamanlayıcısı'),
                      const SizedBox(height: 12.0),
                      Text(
                        _formatDuration(_remainingSeconds),
                        style: textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isTimerRunning &&
                                    _remainingSeconds < 11 &&
                                    _remainingSeconds > 0
                                ? Colors.red.shade700
                                : primaryColor,
                            letterSpacing: 2.0),
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.refresh),
                              iconSize: 30,
                              color: _timerStarted
                                  ? Colors.grey[700]
                                  : Colors.grey[400],
                              tooltip: 'Sıfırla',
                              onPressed: _timerStarted ? _resetTimer : null),
                          const SizedBox(width: 20),
                          IconButton(
                              icon: Icon(_isTimerRunning
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled),
                              iconSize: 50,
                              color: accentColor,
                              tooltip: _isTimerRunning ? 'Durdur' : 'Başlat',
                              onPressed: _remainingSeconds >= 0
                                  ? (_isTimerRunning
                                      ? _pauseTimer
                                      : _startTimer)
                                  : null),
                          const SizedBox(width: 20 + 30),
                        ],
                      ),
                    ],
                  ),
                ),
              if (showTimer)
                const Divider(
                    height: 24, thickness: 1, indent: 16, endIndent: 16),
              buildSectionTitle('Gerekli Malzemeler'),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.recipe.ingredients
                      .map((ingredient) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_box_outline_blank,
                                    size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ingredient,
                                    style: textTheme.bodyLarge
                                        ?.copyWith(height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const Divider(
                  height: 24, thickness: 1, indent: 16, endIndent: 16),
              buildSectionTitle('Yapım Aşamaları'),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.recipe.steps.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${index + 1}.",
                            style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: accentColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.recipe.steps[index],
                              style:
                                  textTheme.bodyLarge?.copyWith(height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ],
      ),
    );
  }
}

Widget buildMacroInfo(IconData icon, String value, String label, Color color) {
  return Column(
    children: [
      Icon(icon, size: 28, color: color),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ],
  );
}

Widget buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.grey[850],
      ),
    ),
  );
}

Widget buildVideoPlayerPlaceholder(BuildContext context, Color accentColor) {
  return Container(
    color: Colors.black87,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline_rounded,
              color: Colors.white70, size: 70),
          const SizedBox(height: 10),
          Text('Video Yüklenecek...',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    ),
  );
}
