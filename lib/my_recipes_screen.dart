// lib/screens/my_recipes_screen.dart
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/api_service.dart';
import '../widgets/recipe_card.dart';
import 'RecipeDetailScreen.dart';
import 'add_edit_recipe_screen.dart'; // Bu ekranın da RecipeModel aldığından emin olun

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({Key? key}) : super(key: key);

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<RecipeModel>> _myRecipesFuture;

  @override
  void initState() {
    super.initState();
    _loadMyRecipes();
  }

  void _loadMyRecipes() {
    setState(() {
      _myRecipesFuture = _apiService.getMyRecipes();
    });
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, RecipeModel recipeToDelete) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tarifi Sil'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    '"${recipeToDelete.title}" tarifini silmek istediğinize emin misiniz?'),
                const SizedBox(height: 8),
                const Text('Bu işlem geri alınamaz.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Evet, Sil'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await _apiService.deleteRecipe(recipeToDelete.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('"${recipeToDelete.title}" silindi!'),
                        backgroundColor: Colors.green),
                  );
                  _loadMyRecipes(); // Listeyi yenile
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Tarif silinemedi: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar'ı HomeScreen yönettiği için burada olmayabilir veya basit bir başlık olabilir
      // Eğer bu ekran ayrıysa AppBar ekleyebilirsiniz:
      appBar: AppBar(
        title: const Text('Tariflerim'),
        automaticallyImplyLeading:
            false, // Eğer alt sekme ise geri butonu olmasın
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Yeni Tarif Ekle',
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddEditRecipeScreen()),
              );
              if (result == true && mounted) {
                _loadMyRecipes();
              }
            },
          ),
          IconButton(
            // Yenile butonu
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _loadMyRecipes,
          ),
        ],
      ),
      body: FutureBuilder<List<RecipeModel>>(
        future: _myRecipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            if (snapshot.error.toString().contains('Yetkisiz')) {
              return const Center(
                  child: Text('Tariflerinizi görmek için giriş yapmalısınız.'));
            }
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Tarifleriniz yüklenemedi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ));
          } else if (snapshot.hasData) {
            final myRecipes = snapshot.data!;
            if (myRecipes.isEmpty) {
              return const Center(
                  child: Text('Henüz hiç tarif eklememişsiniz.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                  top: 16.0, left: 16.0, right: 16.0, bottom: 80.0),
              itemCount: myRecipes.length,
              itemBuilder: (ctx, index) {
                final recipe = myRecipes[index];
                return RecipeCard(
                  recipe: recipe,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: Colors.blueGrey,
                        tooltip: 'Düzenle',
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddEditRecipeScreen(recipeToEdit: recipe),
                            ),
                          );
                          if (result == true && mounted) {
                            _loadMyRecipes();
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.redAccent,
                        tooltip: 'Sil',
                        onPressed: () =>
                            _showDeleteConfirmationDialog(context, recipe),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('Tarif verisi yok.'));
          }
        },
      ),
    );
  }
}
