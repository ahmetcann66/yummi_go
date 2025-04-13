// lib/screens/select_ingredients_screen.dart
import 'package:flutter/material.dart';
import 'RecipesScreen.dart';
// import '../services/api_service.dart'; // API'den malzeme çekmek için

class SelectIngredientsScreen extends StatefulWidget {
  const SelectIngredientsScreen({super.key});
  @override
  State<SelectIngredientsScreen> createState() =>
      _SelectIngredientsScreenState();
}

class _SelectIngredientsScreenState extends State<SelectIngredientsScreen> {
  // TODO: Malzemeleri API'den veya başka bir yerden çek
  final Set<String> _allIngredients = {
    "Tavuk",
    "Soğan",
    "Domates",
    "Pirinç",
    "Un",
    "Yumurta",
    "Süt",
    "Yağ",
    "Tuz",
    "Karabiber",
    "Salça",
    "Mercimek",
    "Bulgur",
    "Nohut",
    "Muz",
    "Çikolata"
  }.toSet();
  final Set<String> _selectedIngredients = {};
  bool _isLoading = false;

  void _findAndNavigate() {
    if (_selectedIngredients.isEmpty) return;
    final List<String> selectedList = _selectedIngredients.toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipesScreen(
          ingredients: selectedList,
          titleOverride: "Malzemelerinizle Tarifler",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(title: const Text('Malzemeleri Seçin')),
          body: const Center(child: CircularProgressIndicator()));
    }
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(title: const Text('Malzemeleri Seçin')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Elinizdeki malzemeleri seçin ve onlarla yapabileceğiniz tarifleri bulun.',
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _allIngredients.isEmpty
                ? const Center(child: Text("Malzeme bulunamadı."))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _allIngredients.map((ingredient) {
                        final bool isSelected =
                            _selectedIngredients.contains(ingredient);
                        return FilterChip(
                          label: Text(ingredient),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedIngredients.add(ingredient);
                              } else {
                                _selectedIngredients.remove(ingredient);
                              }
                            });
                          },
                          selectedColor: accentColor.withOpacity(0.2),
                          checkmarkColor: accentColor,
                          labelStyle: TextStyle(
                            color: isSelected ? accentColor : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: isSelected
                                  ? accentColor.withOpacity(0.5)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          showCheckmark: true,
                        );
                      }).toList(),
                    ),
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, 16 + MediaQuery.of(context).padding.bottom * 0.5),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                    child: Text(
                        "${_selectedIngredients.length} malzeme seçildi",
                        style: TextStyle(color: Colors.grey[600]))),
                ElevatedButton.icon(
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Tarifleri Bul'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12)),
                  onPressed:
                      _selectedIngredients.isEmpty ? null : _findAndNavigate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
