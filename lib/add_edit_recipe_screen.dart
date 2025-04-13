// lib/screens/add_edit_recipe_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe_model.dart';
import '../models/recipe_create_model.dart';
import '../services/api_service.dart';

class AddEditRecipeScreen extends StatefulWidget {
  final RecipeModel? recipeToEdit; // Nullable olabilir

  const AddEditRecipeScreen({super.key, this.recipeToEdit});

  @override
  State<AddEditRecipeScreen> createState() => _AddEditRecipeScreenState();
}

class _AddEditRecipeScreenState extends State<AddEditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controller'lar
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _ingredientsController;
  late TextEditingController _stepsController;
  late TextEditingController _imageUrlController;
  late TextEditingController _videoUrlController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _cookingTimeController;
  String? _selectedCategory; // Seçilen kategori

  bool _isSaving = false; // Kaydetme işlemi sürüyor mu?
  bool get _isEditMode => widget.recipeToEdit != null; // Düzenleme modu mu?

  List<String> _categories = ['Diğer']; // Başlangıç kategorileri

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Kategorileri yükle
    final recipe = widget.recipeToEdit; // Düzenlenecek tarif (null olabilir)

    // Controller'ları başlat (düzenleme moduysa mevcut değerlerle, değilse boş)
    _titleController =
        TextEditingController(text: _isEditMode ? recipe!.title : '');
    _descriptionController =
        TextEditingController(text: _isEditMode ? recipe!.description : '');
    _ingredientsController = TextEditingController(
        text: _isEditMode ? recipe!.ingredients.join('\n') : '');
    _stepsController = TextEditingController(
        text: _isEditMode ? recipe!.steps.join('\n') : '');
    _imageUrlController =
        TextEditingController(text: _isEditMode ? recipe!.imageUrl : '');
    _videoUrlController =
        TextEditingController(text: _isEditMode ? recipe!.videoUrl ?? '' : '');
    _caloriesController = TextEditingController(
        text: _isEditMode ? recipe!.calories?.toString() ?? '' : '');
    _proteinController = TextEditingController(
        text: _isEditMode ? recipe!.protein?.toString() ?? '' : '');
    _carbsController = TextEditingController(
        text: _isEditMode ? recipe!.carbs?.toString() ?? '' : '');
    _fatController = TextEditingController(
        text: _isEditMode ? recipe!.fat?.toString() ?? '' : '');
    _cookingTimeController = TextEditingController(
        text:
            _isEditMode ? recipe!.cookingTimeInMinutes?.toString() ?? '' : '');
    _selectedCategory = _isEditMode ? recipe!.category : null;
  }

  // API'den kategorileri yükleyen metot
  Future<void> _loadCategories() async {
    try {
      final categoriesFromApi = await _apiService.getCategories();
      if (mounted) {
        // Widget hala ağaçtaysa state'i güncelle
        setState(() {
          _categories =
              categoriesFromApi.isNotEmpty ? categoriesFromApi : ['Diğer'];
          // Düzenleme modunda, mevcut kategori API'den gelen listede yoksa seçimi kaldır
          if (_isEditMode &&
              _selectedCategory != null &&
              !_categories.contains(_selectedCategory)) {
            _selectedCategory = null;
          }
        });
      }
    } catch (e) {
      print("Kategoriler yüklenemedi: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Kategoriler yüklenemedi.'),
            backgroundColor: Colors.orange));
      }
    }
  }

  @override
  void dispose() {
    // Controller'ları temizle
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _cookingTimeController.dispose();
    super.dispose();
  }

  // Tarifi kaydetme/güncelleme fonksiyonu
  Future<void> _saveRecipe() async {
    // Formu doğrula (Null check eklendi)
    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (!formIsValid || _isSaving) {
      return;
    }

    // Kategori seçilmiş mi kontrol et
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen bir kategori seçin.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    _formKey.currentState!.save(); // onSaved fonksiyonlarını çalıştırır (varsa)
    setState(() {
      _isSaving = true;
    }); // Yükleme durumunu başlat

    // API'ye gönderilecek modeli oluştur
    final recipeData = RecipeCreateModel(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      ingredients:
          _ingredientsController.text.trim(), // '\n' ile ayrılmış string
      steps: _stepsController.text.trim(), // '\n' ile ayrılmış string
      category: _selectedCategory!,
      imageUrl: _imageUrlController.text.trim(),
      videoUrl: _videoUrlController.text.trim().isEmpty
          ? null
          : _videoUrlController.text.trim(),
      calories: int.tryParse(_caloriesController.text.trim()),
      protein: int.tryParse(_proteinController.text.trim()),
      carbs: int.tryParse(_carbsController.text.trim()),
      fat: int.tryParse(_fatController.text.trim()),
      cookingTimeInMinutes: int.tryParse(_cookingTimeController.text.trim()),
    );

    try {
      String successMessage;
      if (_isEditMode) {
        // Güncelleme API çağrısı
        await _apiService.updateRecipe(widget.recipeToEdit!.id, recipeData);
        successMessage = 'Tarif başarıyla güncellendi!';
      } else {
        // Yeni tarif ekleme API çağrısı
        await _apiService.createRecipe(recipeData);
        successMessage = 'Tarif başarıyla eklendi!';
      }
      // Başarılı olursa mesaj göster ve önceki ekrana dön (değişiklik olduğunu bildir)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(successMessage), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // true: değişiklik yapıldı
      }
    } catch (e) {
      // Hata olursa mesaj göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('İşlem başarısız: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      // İşlem bittiğinde yükleme durumunu kaldır
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Tarifi Düzenle' : 'Yeni Tarif Ekle'),
        actions: [
          // Kaydet butonu (işlem sürüyorsa devre dışı)
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            onPressed: _isSaving ? null : _saveRecipe,
            tooltip: 'Kaydet',
          ),
        ],
      ),
      // Form alanlarının taşmasını önlemek için SingleChildScrollView
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Form anahtarını ata
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Alanları genişlet
            children: [
              // Görsel URL Alanı
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Görsel URL *',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.image_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Görsel URL zorunludur.';
                  // Basit URL format kontrolü
                  final uri = Uri.tryParse(value.trim());
                  if (uri == null || !uri.isAbsolute)
                    return 'Geçerli bir URL girin.';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tarif Adı Alanı
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Tarif Adı *',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder()),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Tarif adı boş bırakılamaz.';
                  if (value.trim().length < 3)
                    return 'Tarif adı en az 3 karakter olmalı.';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kategori Seçimi Alanı
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Kategori Seçin *'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                items: _categories.map((String category) {
                  // _categories listesi kullanılır
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Lütfen bir kategori seçin.' : null,
              ),
              const SizedBox(height: 16),

              // Açıklama Alanı
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Tarifiniz hakkında kısa bir bilgi...',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true),
                maxLines: 3,
                textInputAction: TextInputAction.next,
                // Açıklama zorunlu değilse validator'a gerek yok
              ),
              const SizedBox(height: 24),

              // Malzemeler Alanı
              Text('Malzemeler *',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Her malzemeyi yeni bir satıra yazın.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ingredientsController,
                decoration: const InputDecoration(
                    hintText: '1 su bardağı un\n2 adet yumurta...',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0)),
                minLines: 6,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.next, // Adımlara geçmek için
                validator: (value) {},
              ),
              const SizedBox(height: 24),

              // Yapım Aşamaları Alanı
              Text('Yapım Aşamaları *',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Her adımı yeni bir satıra yazın.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stepsController,
                decoration: const InputDecoration(
                    hintText: '1. Yumurtaları çırpın...',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0)),
                minLines: 8,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction:
                    TextInputAction.next, // Video URL'ye geçmek için
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Yapım aşamaları boş bırakılamaz.';
                  // Satır sayısını kontrol et (en az 1 adım)
                  if (value
                          .split('\n')
                          .where((l) => l.trim().isNotEmpty)
                          .length <
                      1) return 'En az 1 adım girmelisiniz.';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Video URL Alanı (Opsiyonel)
              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                    labelText: 'Video URL (Opsiyonel)',
                    prefixIcon: Icon(Icons.video_call_outlined),
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                // Validator null safety düzeltmesi ile
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final uri = Uri.tryParse(value.trim());
                    // Geçerli bir absolute URL değilse hata ver
                    if (uri == null || !uri.isAbsolute) {
                      return 'Geçerli bir URL girin.';
                    }
                  }
                  return null; // Boş veya geçerli ise sorun yok
                },
              ),
              const SizedBox(height: 24),

              // Besin Değerleri Alanları (Opsiyonel)
              Text('Besin Değerleri (Opsiyonel)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: TextFormField(
                        controller: _caloriesController,
                        decoration: const InputDecoration(
                            labelText: 'Kalori (kcal)',
                            prefixIcon:
                                Icon(Icons.local_fire_department_outlined)),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        textInputAction: TextInputAction.next)),
                const SizedBox(width: 12),
                Expanded(
                    child: TextFormField(
                        controller: _proteinController,
                        decoration: const InputDecoration(
                            labelText: 'Protein (g)',
                            prefixIcon: Icon(Icons.fitness_center)),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        textInputAction: TextInputAction.next)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: TextFormField(
                        controller: _carbsController,
                        decoration: const InputDecoration(
                            labelText: 'Karb (g)',
                            prefixIcon: Icon(Icons.breakfast_dining_outlined)),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        textInputAction: TextInputAction.next)),
                const SizedBox(width: 12),
                Expanded(
                    child: TextFormField(
                        controller: _fatController,
                        decoration: const InputDecoration(
                            labelText: 'Yağ (g)',
                            prefixIcon: Icon(Icons.water_drop_outlined)),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        textInputAction: TextInputAction.next)),
              ]),
              const SizedBox(height: 16),

              // Pişirme Süresi Alanı (Opsiyonel)
              TextFormField(
                controller: _cookingTimeController,
                decoration: const InputDecoration(
                    labelText: 'Pişirme Süresi (dk - Opsiyonel)',
                    prefixIcon: Icon(Icons.timer_outlined)),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done, // Formdaki son alan
              ),
              const SizedBox(height: 40), // En alta boşluk
            ],
          ),
        ),
      ),
    );
  }
}
