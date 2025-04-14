// lib/screens/RecipesScreen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recipe_model.dart';
import 'RecipeDetailScreen.dart';
import '../widgets/recipe_card.dart';

class RecipesScreen extends StatefulWidget {
  final String? category;
  final String? titleOverride;
  final String? searchQuery;
  final List<String>? ingredients;
  final int? userId; // YENİ: Kullanıcı ID'si parametresi

  const RecipesScreen({
    super.key,
    this.category,
    this.titleOverride,
    this.searchQuery,
    this.ingredients,
    this.userId, // YENİ: Kurucuya ekle
  });

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<RecipeModel>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  void _loadRecipes() {
    setState(() {
      if (widget.userId != null) {
        // Eğer userId parametresi varsa, kullanıcıya ait tarifleri çek
        _recipesFuture = _apiService.getRecipesByUserId(widget.userId!);
      } else {
        // Aksi takdirde, mevcut filtreleme mantığını kullan
        _recipesFuture = _apiService.getRecipes(
          category: widget.category,
          search: widget.searchQuery,
          ingredients: widget.ingredients,
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant RecipesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.category != oldWidget.category ||
        widget.searchQuery != oldWidget.searchQuery ||
        widget.ingredients != oldWidget.ingredients ||
        widget.titleOverride != oldWidget.titleOverride ||
        widget.userId != oldWidget.userId) {
      _loadRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    if (widget.searchQuery != null && widget.searchQuery!.trim().isNotEmpty) {
      appBarTitle = 'Arama: "${widget.searchQuery}"';
    } else if (widget.ingredients != null && widget.ingredients!.isNotEmpty) {
      appBarTitle = widget.titleOverride ?? 'Malzemelerle Tarifler';
    } else if (widget.category != null) {
      appBarTitle = widget.titleOverride ?? widget.category!;
    } else {
      appBarTitle = widget.titleOverride ?? 'Tarifler';
    }

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: FutureBuilder<List<RecipeModel>>(
        future: _recipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("RecipesScreen FutureBuilder Hata: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tarifler yüklenirken bir hata oluştu.\n(${snapshot.error})',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                      onPressed: _loadRecipes,
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final displayedRecipes = snapshot.data!;
            if (displayedRecipes.isEmpty) {
              String emptyMessage = 'Gösterilecek tarif yok.';
              if (widget.searchQuery != null)
                emptyMessage = '"${widget.searchQuery}" için sonuç bulunamadı.';
              else if (widget.category != null)
                emptyMessage =
                    '"${widget.category}" kategorisinde tarif bulunamadı.';
              else if (widget.ingredients != null)
                emptyMessage = 'Seçilen malzemelerle tarif bulunamadı.';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
              itemCount: displayedRecipes.length,
              itemBuilder: (context, index) {
                final recipe = displayedRecipes[index];
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
            return const Center(child: Text('Tarif verisi alınamadı.'));
          }
        },
      ),
    );
  }
}
