import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider paketini import et
// --- Gerekli Importlar (Yolları Kontrol Edin!) ---
import '../models/RecipeModel.dart';
import '../services/RecipeService.dart'; // RecipeService importu (DOĞRU)
// ApiResponse modeli RecipeService veya ortak bir dosyada olmalı
// import '../services/LoginService.dart'; // GEREKMEYEBİLİR (ApiResponse için)
import '../widgets/recipe_card.dart';
import 'RecipeDetailScreen.dart';
import 'AddEditRecipeScreen.dart';
// -------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final RecipeService _recipeService = RecipeService(); // <<< BU SATIRI SİLİN
  late RecipeService _recipeServiceInstance; // <<< Servisi tutmak için değişken
  late Future<List<RecipeModel>> _myRecipesFuture;
  bool _isInitialized = false; // Provider'ı bir kez almak için flag

  @override
  void initState() {
    super.initState();
    // initState'te context'e erişim güvenli DEĞİLDİR (Provider.of için).
    // Bu yüzden yüklemeyi didChangeDependencies'e taşıyoruz.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider.of'u çağırmak için güvenli yer. Sadece ilk seferde çalıştır.
    if (!_isInitialized) {
      // Provider'dan RecipeService örneğini al ve değişkene ata
      _recipeServiceInstance = Provider.of<RecipeService>(context);
      // Future'ı burada başlat
      _loadMyRecipes();
      _isInitialized = true;
    }
  }

  /// Reçeteleri yüklemek için Future'ı ayarlar.
  void _loadMyRecipes() {
    if (!mounted) return;
    setState(() {
      // _recipeServiceInstance artık kullanılabilir
      _myRecipesFuture = _fetchAndProcessRecipes();
    });
  }

  /// Asıl API çağrısını yapar (Artık _recipeServiceInstance kullanır).
  Future<List<RecipeModel>> _fetchAndProcessRecipes() async {
    // Provider'dan alınan _recipeServiceInstance'ı kullan
    final ApiResponse<List<RecipeModel>> apiResponse =
        await _recipeServiceInstance.getMyRecipes(); // <<< DEĞİŞTİ

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    } else {
      throw Exception(apiResponse.message ?? 'Tarifler yüklenemedi');
    }
  }

  /// Tarif silme onayı iletişim kutusunu gösteren metot.
  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, RecipeModel recipeToDelete) async {
    // Bu fonksiyon zaten context alıyor, Provider'ı burada da kullanabiliriz
    // ancak _recipeServiceInstance zaten mevcut olduğu için onu kullanmak daha temiz.

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Tarifi Sil'),
            content: Text(
                '"${recipeToDelete.title}" tarifini silmek istediğinize emin misiniz?\nBu işlem geri alınamaz.'),
            actions: <Widget>[
              TextButton(
                child: const Text('İptal'),
                onPressed:
                    isDeleting ? null : () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setStateDialog(() => isDeleting = true);
                        try {
                          // _recipeServiceInstance'ı kullan
                          final response =
                              await _recipeServiceInstance // <<< DEĞİŞTİ
                                  .deleteRecipe(recipeToDelete.id);

                          Navigator.of(dialogContext).pop(); // Dialog'u kapat
                          if (!mounted) return;

                          if (response.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(response.message ??
                                      '"${recipeToDelete.title}" silindi!'),
                                  backgroundColor: Colors.green),
                            );
                            _loadMyRecipes(); // Listeyi yenile
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      response.message ?? 'Tarif silinemedi.'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        } catch (e) {
                          Navigator.of(dialogContext)
                              .pop(); // Hata durumunda da kapat
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Tarif silinirken bir hata oluştu: $e'),
                                backgroundColor: Colors.red),
                          );
                          print("Silme Hatası: $e");
                        } finally {
                          // finally bloğuna gerek yok, isDeleting zaten state'i yönetiyor
                          // ve dialog kapatılıyor.
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('Evet, Sil'),
              ),
            ],
          );
        });
      },
    );
  }

  /// Yeni tarif ekleme veya mevcut tarifi düzenleme ekranına yönlendiren metot.
  Future<void> _navigateToAddEditScreen({RecipeModel? recipe}) async {
    // Bu metot context'i Navigator için kullanıyor.
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        // AddEditRecipeScreen zaten Provider'dan kendi servisini alıyor
        builder: (context) => AddEditRecipeScreen(recipeToEdit: recipe),
      ),
    );
    // Ekleme/Düzenleme ekranından 'true' dönerse (başarılıysa) listeyi yenile
    if (result == true && mounted) {
      _loadMyRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    // _isInitialized kontrolü sayesinde build metodu tekrar çalıştığında
    // Provider.of tekrar çağrılmaz veya _loadMyRecipes gereksiz yere tetiklenmez.
    if (!_isInitialized) {
      // Henüz initialize olmadıysa (çok nadir bir durum olabilir), yükleniyor göster
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tariflerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Yeni Tarif Ekle',
            onPressed: () => _navigateToAddEditScreen(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed:
                _loadMyRecipes, // Bu Future'ı ve dolayısıyla _fetch'i tetikler
          ),
        ],
      ),
      body: RefreshIndicator(
        // onRefresh doğrudan _fetchAndProcessRecipes'i çağırabilir,
        // çünkü _recipeServiceInstance artık mevcut.
        onRefresh: _fetchAndProcessRecipes,
        child: FutureBuilder<List<RecipeModel>>(
          future: _myRecipesFuture, // State'de tutulan Future'ı kullan
          builder: (context, snapshot) {
            // --- Yükleniyor Durumu ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // --- Hata Durumu ---
            else if (snapshot.hasError) {
              final errorMessage =
                  snapshot.error.toString().replaceFirst('Exception: ', '');
              String displayMessage = errorMessage;
              // Oturum hatası özel mesajı
              if (errorMessage.contains('oturum açmalısınız') ||
                  errorMessage.contains('Unauthorized')) {
                displayMessage =
                    'Tariflerinizi görmek için oturum açmalısınız.';
                // İsteğe bağlı: Kullanıcıyı otomatik login ekranına yönlendirebilirsiniz.
                // WidgetsBinding.instance.addPostFrameCallback((_) {
                //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                // });
              }

              // Hata durumunda kullanıcıya mesaj ve yenileme butonu göstermek iyi olabilir.
              return ListView(
                // Kaydırılabilir olması için ListView içinde
                physics:
                    const AlwaysScrollableScrollPhysics(), // RefreshIndicator için
                children: [
                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.2), // Ortalamak için boşluk
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                              size: 50),
                          const SizedBox(height: 15),
                          Text(displayMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 16)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tekrar Dene'),
                            onPressed: _loadMyRecipes,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            // --- Veri Başarıyla Geldi Durumu ---
            else if (snapshot.hasData) {
              final myRecipes = snapshot.data!;
              if (myRecipes.isEmpty) {
                // Boş liste durumu
                return ListView(
                    // RefreshIndicator için ListView gerekli
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height *
                              0.2), // Ortalamak için
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                              'Henüz hiç tarif eklememişsiniz.\n'
                              'Sağ üst köşedeki (+) ikonuna dokunarak başlayın!',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey)),
                        ),
                      ),
                    ]);
              }

              // Dolu liste durumu (ListView.builder aynı kalır)
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: myRecipes.length,
                itemBuilder: (ctx, index) {
                  final recipe = myRecipes[index];
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
                      // Detaydan dönünce yenileme GEREKMEYEBİLİR,
                      // çünkü AddEditScreen'den dönünce zaten yeniliyoruz.
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: Colors.blueGrey,
                          tooltip: 'Düzenle',
                          onPressed: () =>
                              _navigateToAddEditScreen(recipe: recipe),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
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
            }
            // --- Diğer Beklenmedik Durumlar ---
            else {
              return ListView(
                  // RefreshIndicator için ListView
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    Center(child: Text('Tarif verisi bulunamadı.'))
                  ]);
            }
          },
        ),
      ),
    );
  }
}
