// lib/screens/add_edit_recipe_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Provider paketini import et
import '../models/RecipeModel.dart'; // Tarif modeli (Yolu doğrulayın)
import '../services/RecipeService.dart'; // RecipeService importu (Yolu doğrulayın)
// ApiResponse modeli RecipeService veya ortak bir dosyada tanımlı olmalı
// ve burada import edilmeli veya RecipeService.ApiResponse olarak kullanılmalı.
// Örnek: import '../services/api_response.dart';

class AddEditRecipeScreen extends StatefulWidget {
  // Düzenlenecek tarif (opsiyonel). Eğer null ise yeni tarif eklenir.
  final RecipeModel? recipeToEdit;

  const AddEditRecipeScreen({Key? key, this.recipeToEdit}) : super(key: key);

  @override
  State<AddEditRecipeScreen> createState() => _AddEditRecipeScreenState();
}

class _AddEditRecipeScreenState extends State<AddEditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  // final RecipeService _recipeService = RecipeService(); // <<< DOĞRUDAN OLUŞTURMA KALDIRILDI
  bool _isLoading = false;

  // Form alanları için Controller'lar
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _ingredientsController; // Malzemeler (tek string)
  late TextEditingController _stepsController; // Adımlar (tek string)
  late TextEditingController _categoryController;
  late TextEditingController _imageUrlController;
  late TextEditingController _videoUrlController; // Video URL (opsiyonel)
  late TextEditingController _caloriesController; // Besin değerleri (opsiyonel)
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _cookingTimeController; // Pişirme Süresi

  // Düzenleme modunda olup olmadığını kontrol eden getter
  bool get _isEditing => widget.recipeToEdit != null;

  @override
  void initState() {
    super.initState();
    // Ekran başladığında, düzenleme modundaysa mevcut tarif verileriyle,
    // değilse boş olarak controller'ları başlat.
    final recipe = widget.recipeToEdit;
    _titleController = TextEditingController(text: recipe?.title ?? '');
    _descriptionController =
        TextEditingController(text: recipe?.description ?? '');
    _ingredientsController =
        TextEditingController(text: recipe?.ingredients ?? '');
    _stepsController = TextEditingController(text: recipe?.steps ?? '');
    _categoryController = TextEditingController(text: recipe?.category ?? '');
    _imageUrlController = TextEditingController(text: recipe?.imageUrl ?? '');
    _videoUrlController = TextEditingController(text: recipe?.videoUrl ?? '');
    // Sayısal değerleri String'e çevirerek ata (nullable kontrolü ile)
    _caloriesController =
        TextEditingController(text: recipe?.calories?.toString() ?? '');
    _proteinController =
        TextEditingController(text: recipe?.protein?.toString() ?? '');
    _carbsController =
        TextEditingController(text: recipe?.carbs?.toString() ?? '');
    _fatController = TextEditingController(text: recipe?.fat?.toString() ?? '');
    _cookingTimeController = TextEditingController(
        text: recipe?.cookingTimeInMinutes?.toString() ?? '');
  }

  @override
  void dispose() {
    // Kaynak sızıntısını önlemek için tüm controller'ları dispose et.
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _cookingTimeController.dispose();
    super.dispose();
  }

  /// Formu doğrular ve tarifi API'ye kaydeder veya günceller.
  Future<void> _saveRecipe() async {
    // Form geçerli değilse veya zaten bir işlem yapılıyorsa çık
    if (!_formKey.currentState!.validate() || _isLoading) return;

    // --- Servisi Provider'dan al ---
    // Context'e erişim olduğu için burada Provider.of kullanabiliriz.
    // `listen: false` önemlidir, çünkü servis state'i değiştiğinde
    // bu ekranın yeniden build olmasına gerek yoktur.
    final recipeService = Provider.of<RecipeService>(context, listen: false);

    // Yükleme durumunu başlat ve UI'ı güncelle
    setState(() {
      _isLoading = true;
    });

    try {
      // Formdaki verilerden RecipeModel nesnesi oluştur
      final RecipeModel recipeData = RecipeModel(
        // Düzenleme modundaysa mevcut ID'yi, değilse 0 (veya null) kullan
        id: widget.recipeToEdit?.id ?? 0,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        ingredients: _ingredientsController.text.trim(),
        steps: _stepsController.text.trim(),
        category: _categoryController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        // Video URL boşsa null ata
        videoUrl: _videoUrlController.text.trim().isEmpty
            ? null
            : _videoUrlController.text.trim(),
        // Sayısal alanları int'e çevir (başarısız olursa null olur - tryParse)
        calories: int.tryParse(_caloriesController.text),
        protein: int.tryParse(_proteinController.text),
        carbs: int.tryParse(_carbsController.text),
        fat: int.tryParse(_fatController.text),
        cookingTimeInMinutes: int.tryParse(_cookingTimeController.text),
        // userId ve user gibi alanlar burada GÖNDERİLMEZ.
        // RecipeService.addRecipe içinde AuthManager'dan alınır.
        // RecipeService.updateRecipe ise genellikle sadece ID'ye bakar.
      );

      // --- API İsteği: Düzenleme mi, Ekleme mi? ---
      // ApiResponse tipini belirtmek daha sağlıklıdır.
      // RecipeService içindeki tanımla eşleşmelidir.
      ApiResponse<RecipeModel> response;

      if (_isEditing) {
        // Düzenleme modundaysa updateRecipe'i çağır
        print("Tarif güncelleniyor: ID=${recipeData.id}");
        response = await recipeService.updateRecipe(recipeData);
      } else {
        // Yeni tarif ekleme modundaysa addRecipe'i çağır
        print("Yeni tarif ekleniyor...");
        response = await recipeService.addRecipe(recipeData);
      }

      // Widget ağaçtan kaldırıldıysa işlem yapma (asenkron işlem sonrası kontrol)
      if (!mounted) return;

      // --- Yanıtı İşle ---
      if (response.success) {
        // Başarılıysa kullanıcıya mesaj göster ve önceki ekrana dön (true değeriyle)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isEditing
                ? 'Tarif başarıyla güncellendi!'
                : 'Tarif başarıyla eklendi!'),
            backgroundColor: Colors.green[600]));
        // true değeri, HomeScreen gibi önceki ekranın listeyi yenilemesi gerektiğini belirtir.
        Navigator.of(context).pop(true);
      } else {
        // Başarısızsa API'den gelen veya varsayılan hata mesajını göster
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Hata: ${response.message ?? (_isEditing ? "Tarif güncellenemedi" : "Tarif eklenemedi")}'),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    } catch (e) {
      // API çağrısı veya başka bir aşamada beklenmedik bir hata olursa
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Beklenmedik bir hata oluştu: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
      print("Tarif Kaydetme/Güncelleme Sırasında Genel Hata: $e");
    } finally {
      // İşlem başarılı da olsa, başarısız da olsa yükleme durumunu bitir
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Ekran başlığını düzenleme veya ekleme moduna göre ayarla
        title: Text(_isEditing ? 'Tarifi Düzenle' : 'Yeni Tarif Ekle'),
        actions: [
          // Kaydet butonu
          IconButton(
            // Yükleme sırasında butonu devre dışı bırak ve ikon değiştir
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            tooltip: 'Kaydet',
            onPressed:
                _isLoading ? null : _saveRecipe, // _saveRecipe metodunu çağırır
          ),
        ],
      ),
      // Formun taşmasını önlemek ve klavye açıldığında kaydırmak için SingleChildScrollView
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Formun state'ini yönetmek için anahtar
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Çocukları yatayda genişlet
            children: <Widget>[
              // Tarif Başlığı Alanı
              TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: 'Tarif Başlığı',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title)),
                  validator: (value) {
                    // Basit boş kontrolü
                    if (value == null || value.trim().isEmpty) {
                      return 'Tarif başlığı boş bırakılamaz.';
                    }
                    return null;
                  },
                  textInputAction:
                      TextInputAction.next // Klavyede "sonraki" tuşu
                  ),
              const SizedBox(height: 16.0), // Alanlar arası boşluk

              // Açıklama Alanı
              TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true),
                  maxLines: 3, // Birden fazla satır izin ver
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Açıklama boş bırakılamaz.';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next),
              const SizedBox(height: 16.0),

              // Malzemeler Alanı
              TextFormField(
                controller: _ingredientsController,
                decoration: const InputDecoration(
                    labelText: 'Malzemeler',
                    alignLabelWithHint: true, // Label'ı yukarıda tutar
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.list_alt_outlined),
                    hintText: 'Her malzemeyi yeni bir satıra yazın.'),
                maxLines: null, // Otomatik olarak genişler
                keyboardType: TextInputType.multiline, // Çok satırlı klavye
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Malzemeler boş bırakılamaz.';
                  }
                  return null;
                },
                // Multiline alanlarda textInputAction genellikle newline'dır
                // textInputAction: TextInputAction.newline // veya TextInputAction.next
              ),
              const SizedBox(height: 16.0),

              // Yapılış Adımları Alanı
              TextFormField(
                controller: _stepsController,
                decoration: const InputDecoration(
                    labelText: 'Yapılış Adımları',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.format_list_numbered_outlined),
                    hintText: 'Her adımı yeni bir satıra yazın.'),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Yapılış adımları boş bırakılamaz.';
                  }
                  return null;
                },
                // textInputAction: TextInputAction.newline // veya TextInputAction.next
              ),
              const SizedBox(height: 16.0),

              // Pişirme Süresi Alanı
              TextFormField(
                  controller: _cookingTimeController,
                  decoration: const InputDecoration(
                      labelText: 'Pişirme Süresi (dk)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer_outlined)),
                  keyboardType: TextInputType.number, // Sadece sayı klavyesi
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ], // Sadece rakam girişi
                  validator: (value) {
                    // Boş olabilir ama girildiyse sayı olmalı
                    if (value != null &&
                        value.isNotEmpty &&
                        int.tryParse(value) == null) {
                      return 'Lütfen geçerli bir sayı girin.';
                    }
                    // API sıfır kabul etmiyorsa ek kontrol:
                    // if (value != null && value.isNotEmpty && (int.tryParse(value) ?? 0) <= 0) {
                    //   return 'Süre 0\'dan büyük olmalı.';
                    // }
                    return null;
                  },
                  textInputAction: TextInputAction.next),
              const SizedBox(height: 16.0),

              // Kategori Alanı
              TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined)),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kategori boş bırakılamaz.';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next),
              const SizedBox(height: 16.0),

              // Resim URL Alanı
              TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                      labelText: 'Resim URL\'si',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image_outlined)),
                  keyboardType: TextInputType.url, // URL klavyesi
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Resim URL\'si boş bırakılamaz.'; // API zorunlu tutuyorsa
                    }
                    // Basit URL format kontrolü (daha kapsamlısı eklenebilir)
                    if (!value!.trim().toLowerCase().startsWith('http://') &&
                        !value.trim().toLowerCase().startsWith('https://')) {
                      return 'Lütfen geçerli bir URL girin (http:// veya https:// ile başlamalı).';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next),
              const SizedBox(height: 16.0),

              // Video URL Alanı (Opsiyonel)
              TextFormField(
                  controller: _videoUrlController,
                  decoration: const InputDecoration(
                      labelText: 'Video URL\'si (Opsiyonel)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.videocam_outlined)),
                  keyboardType: TextInputType.url,
                  // Opsiyonel olduğu için validator null dönebilir
                  validator: (value) {
                    if (value != null &&
                        value.trim().isNotEmpty &&
                        !value.trim().toLowerCase().startsWith('http://') &&
                        !value.trim().toLowerCase().startsWith('https://')) {
                      return 'Lütfen geçerli bir URL girin veya boş bırakın.';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next),
              const SizedBox(height: 24.0),

              // Besin Değerleri Bölümü
              Text('Besin Değerleri (Opsiyonel)',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 12.0),

              // Kalori ve Protein (Yan yana)
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Hata mesajları için hizalama
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: _caloriesController,
                          decoration: const InputDecoration(
                              labelText: 'Kalori (kcal)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          // Opsiyonel validator: sadece sayı kontrolü
                          validator: (v) => (v != null &&
                                  v.isNotEmpty &&
                                  int.tryParse(v) == null)
                              ? 'Sayı'
                              : null,
                          textInputAction: TextInputAction.next)),
                  const SizedBox(width: 8.0), // İki alan arası boşluk
                  Expanded(
                      child: TextFormField(
                          controller: _proteinController,
                          decoration: const InputDecoration(
                              labelText: 'Protein (g)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) => (v != null &&
                                  v.isNotEmpty &&
                                  int.tryParse(v) == null)
                              ? 'Sayı'
                              : null,
                          textInputAction: TextInputAction.next)),
                ],
              ),
              const SizedBox(height: 16.0), // Satırlar arası boşluk

              // Karbonhidrat ve Yağ (Yan yana)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: _carbsController,
                          decoration: const InputDecoration(
                              labelText: 'Karb. (g)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) => (v != null &&
                                  v.isNotEmpty &&
                                  int.tryParse(v) == null)
                              ? 'Sayı'
                              : null,
                          textInputAction: TextInputAction.next)),
                  const SizedBox(width: 8.0),
                  Expanded(
                      child: TextFormField(
                          controller: _fatController,
                          decoration: const InputDecoration(
                              labelText: 'Yağ (g)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) => (v != null &&
                                  v.isNotEmpty &&
                                  int.tryParse(v) == null)
                              ? 'Sayı'
                              : null,
                          textInputAction:
                              TextInputAction.done, // Formdaki son alan
                          // Son alanda Enter'a basılınca formu kaydetmeyi dene
                          onFieldSubmitted: (_) =>
                              _isLoading ? null : _saveRecipe())),
                ],
              ),
              const SizedBox(height: 32.0), // Buton öncesi boşluk

              // Kaydet/Güncelle Butonu
              ElevatedButton.icon(
                icon: _isLoading
                    ? Container()
                    : Icon(_isEditing
                        ? Icons.sync_alt
                        : Icons.add_circle_outline), // Buton ikonu
                label: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.white))
                    : Text(_isEditing ? 'Tarifi Güncelle' : 'Tarifi Ekle',
                        style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 15), // Buton yüksekliği
                  // backgroundColor: Theme.of(context).primaryColor // veya accentColor
                ),
                onPressed: _isLoading
                    ? null
                    : _saveRecipe, // _saveRecipe metodunu çağırır
              ),
              const SizedBox(height: 20), // En altta biraz boşluk
            ],
          ),
        ),
      ),
    );
  }
}
