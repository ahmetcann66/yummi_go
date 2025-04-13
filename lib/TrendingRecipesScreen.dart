// lib/screens/trending_recipes_screen.dart
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/api_service.dart';
import 'RecipeDetailScreen.dart';
import '../widgets/recipe_card.dart';

class TrendingRecipesScreen extends StatefulWidget {
  const TrendingRecipesScreen({super.key});

  @override
  State<TrendingRecipesScreen> createState() => _TrendingRecipesScreenState();
}

class _TrendingRecipesScreenState extends State<TrendingRecipesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<RecipeModel>> _trendingRecipesFuture;

  @override
  void initState() {
    super.initState();
    _loadTrendingRecipes();
  }

  void _loadTrendingRecipes() {
    setState(() {
      // API'nizin 'likes_desc' veya benzeri bir sıralamayı desteklediğini varsayıyoruz
      _trendingRecipesFuture = _apiService.getRecipes(sortBy: 'likes_desc');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trend Tarifler')),
      body: FutureBuilder<List<RecipeModel>>(
        future: _trendingRecipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Trend tarifler yüklenemedi: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final trendingRecipes = snapshot.data!;
            if (trendingRecipes.isEmpty) {
              return const Center(child: Text('Trend tarif bulunamadı.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: trendingRecipes.length,
              itemBuilder: (context, index) {
                final recipe = trendingRecipes[index];
                return RecipeCard(
                  recipe: recipe,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return const Center(child: Text('Trend tarif verisi yok.'));
          }
        },
      ),
    );
  }
}
