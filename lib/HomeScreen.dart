// lib/HomeScreen.dart

import 'dart:async'; // Timer için
import 'package:flutter/material.dart';
// --- API ve Modelleri Import Et ---
import 'models/recipe_model.dart'; // API'den gelen tarif modeli
import 'services/api_service.dart'; // API servis sınıfı
// --- Eski Veri ve Modelleri Kaldır/Yorum Yap ---
// import 'package:yummi_go/data/dummy_data.dart';
// import 'Recipe.dart'; // Eski model

// --- Diğer Gerekli Ekran Importları ---
import 'RecipesScreen.dart'; // API'ye bağlı olmalı
import 'CategoriesScreen.dart';
import 'TrendingRecipesScreen.dart'; // API'ye bağlı olmalı
import 'SelectIngredientsScreen.dart'; // API'ye bağlı olmalı
import 'RecipeDetailScreen.dart'; // RecipeModel almalı
import 'ProfileScreen.dart'; // API'ye bağlı olabilir
import 'my_recipes_screen.dart'; // API'ye bağlı olmalı
import 'general_timer_screen.dart';
// --- Ses Tanıma Importları ---
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

// --- Ana HomeScreen Widget'ı ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Alt sekme indeksi

  // --- Gösterilecek Ekranlar ---
  // HomeContent artık API verisi kullanacak şekilde güncellendi
  final List<Widget> _screens = [
    const HomeContent(), // Index 0: Ana İçerik (API Bağlantılı)
    const MyRecipesScreen(), // Index 1: Tariflerim (API Bağlantılı)
    const PlaceholderWidget(
        title: 'Bildirimler'), // Index 2: Bildirimler (Placeholder)
  ];
  // --------------------------

  // --- Ses Tanıma State'leri ---
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _recognizedWords = '';
  String _currentLocaleId = 'tr_TR'; // Türkçe için ayarlandı
  // --------------------------

  @override
  void initState() {
    super.initState();
    _initSpeech(); // Ses tanımayı başlat
  }

  // Ses tanımayı başlatan metot
  void _initSpeech() async {
    try {
      bool available = await _speechToText.initialize(
          onError: (e) => print('Speech Init Error: $e'),
          onStatus: (s) => print('Speech Status: $s'));
      if (available) {
        var locales = await _speechToText.locales();
        LocaleName? selectedLocale;
        // Türkçe locale'i bulmaya çalış
        try {
          selectedLocale =
              locales.firstWhere((l) => l.localeId.startsWith('tr'));
        } catch (e) {
          // Bulamazsa sistem locale'ini veya ilk locale'i kullan
          LocaleName? sysLoc = await _speechToText.systemLocale();
          selectedLocale =
              sysLoc ?? (locales.isNotEmpty ? locales.first : null);
        }

        if (mounted) {
          setState(() {
            _speechEnabled = true;
            _currentLocaleId = selectedLocale?.localeId ?? _currentLocaleId;
          });
        }
        print("Ses tanıma başlatıldı. Dil: $_currentLocaleId");
      } else {
        if (mounted) setState(() => _speechEnabled = false);
        print("Ses tanıma kullanılamıyor.");
      }
    } catch (e) {
      if (mounted) setState(() => _speechEnabled = false);
      print("Ses tanıma hatası: $e");
    }
  }

  // Dinlemeyi başlatan metot
  void _startListening() async {
    if (!_speechEnabled || _isListening) return;
    setState(() {
      _isListening = true;
      _recognizedWords = "";
    });
    print("Dinleme başladı...");
    await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: _currentLocaleId,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        listenMode: ListenMode.confirmation);
    if (mounted) setState(() {});
  }

  // Dinlemeyi durduran ve arama yapan metot
  void _stopListening() async {
    if (!_isListening) return;
    await _speechToText.stop();
    print("Dinleme durdu. Sonuç: $_recognizedWords");
    if (mounted) {
      setState(() {
        _isListening = false;
      });
      final query = _recognizedWords.trim();
      if (query.isNotEmpty) {
        print("Sesli arama sonucu: $query");
        // API'ye bağlı RecipesScreen'e yönlendir
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RecipesScreen(searchQuery: query)));
      }
    }
  }

  // Konuşma sonucunu işleyen metot
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (mounted) {
      setState(() {
        _recognizedWords = result.recognizedWords;
      });
    }
  }

  // Alt navigasyon tıklama yöneticisi
  void _onItemTapped(int index) {
    if (!mounted) return;
    if (index == 3) {
      // Menü (Profil)
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()));
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Ana Scaffold'u oluşturan build metodu
  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      // --- AppBar (Arama ve Sesli Arama ile) ---
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 1,
        leading: const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(Icons.restaurant_menu, color: Colors.white, size: 28),
        ),
        title: Container(
          // Arama Çubuğu
          height: 40,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: TextField(
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
              hintText: "Tarif içinde ara...",
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(
                  left: 0, right: 15, top: 11, bottom: 11),
            ),
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            onSubmitted: (value) {
              // Enter ile arama
              final query = value.trim();
              if (query.isNotEmpty) {
                print("Metinle arama: $query");
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RecipesScreen(
                            searchQuery: query))); // API'ye bağlı ekran
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Lütfen aramak için bir şeyler yazın.'),
                    duration: Duration(seconds: 2)));
              }
            },
            textInputAction: TextInputAction.search,
          ),
        ),
        actions: [
          // Mikrofon Butonu
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none_rounded,
                color: _isListening ? Colors.blue.shade300 : Colors.white,
                size: 28),
            tooltip: _isListening ? 'Dinleniyor...' : 'Sesli arama',
            onPressed: !_speechEnabled
                ? null
                : (_isListening ? _stopListening : _startListening),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // ------------------------------------
      // Gövde (Seçili indekse göre ekranı göster)
      body: IndexedStack(index: _selectedIndex, children: _screens),
      // --- Alt Navigasyon Barı ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'AnaSayfa'), // Index 0
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Tariflerim'), // Index 1
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Bildirimler'), // Index 2
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Menü'), // Index 3
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      // --------------------------
    );
  }
}

// --- Ana Ekran İçeriği (HomeContent - API Bağlantılı) ---
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final PageController _pageController =
      PageController(viewportFraction: 0.88); // Banner kaydırma
  Timer? _timer; // Otomatik kaydırma timer'ı
  int _currentPage = 0; // Hangi banner sayfasında

  // --- API Servisi ve Future ---
  final ApiService _apiService = ApiService();
  late Future<List<RecipeModel>> _topRecipesFuture;
  // -----------------------------

  @override
  void initState() {
    super.initState();
    _loadTopRecipes(); // Ekran açıldığında veriyi yükle
  }

  // API'den en popüler tarifleri yükle
  void _loadTopRecipes() {
    setState(() {
      // API'nizin 'likes_desc' ve 'limit' parametrelerini desteklediğini varsayıyoruz
      //_topRecipesFuture =
      //_apiService.getRecipes(sortBy: 'likes_desc', limit: 5);
      _topRecipesFuture = _apiService.getTopRatedRecipes(limit: 5);
      // Desteklemiyorsa:
      // _topRecipesFuture = _apiService.getRecipes().then((all) {
      //   all.sort((a, b) => b.likeCount.compareTo(a.likeCount));
      //   return all.take(5).toList();
      // });
    });
  }

  // Timer'ı başlatma/kontrol etme
  void _startTimerIfNeeded(int recipeCount) {
    // Sadece 1'den fazla tarif varsa ve widget hala aktifse timer'ı başlat/devam ettir
    if (recipeCount > 1 && mounted && _pageController.hasClients) {
      _timer?.cancel(); // Önceki timer'ı durdur (varsa)
      _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        if (!mounted || !_pageController.hasClients || recipeCount < 2) {
          timer.cancel();
          return; // Eğer widget dispose edildiyse veya tarif sayısı değiştiyse durdur
        }
        int nextPage =
            (_currentPage + 1) % recipeCount; // Bir sonraki sayfaya geç
        _pageController.animateToPage(nextPage,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic);
      });
    } else {
      _timer
          ?.cancel(); // Tarif sayısı yetersizse veya widget aktif değilse timer'ı durdur
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Ekran kapanınca timer'ı durdur
    _pageController.dispose(); // Controller'ı temizle
    super.dispose();
  }

  // HomeContent'in UI'ını oluşturan build metodu
  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    // Arka plan görseli URL'si (butonlar için)
    const String backgroundImageUrl =
        'https://images.unsplash.com/photo-1498837167922-ddd27525d352?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1740&q=80';

    return SingleChildScrollView(
      // Tüm içeriği kaydırılabilir yap
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Otomatik Kayan PageView Banner (FutureBuilder ile) ---
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            // SizedBox yüksekliği PageView + Noktaları içermeli
            child: SizedBox(
              height: MediaQuery.of(context).size.width * (9 / 16) * 0.9 + 30,
              child: FutureBuilder<List<RecipeModel>>(
                future: _topRecipesFuture, // API'den gelen veriyi bekle
                builder: (context, snapshot) {
                  // Yükleniyor durumu
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Yüklenirken banner alanı kadar yer kapla
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Hata durumu
                  else if (snapshot.hasError) {
                    print("HomeContent Banner Hata: ${snapshot.error}");
                    return Center(
                        child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          'Popüler tarifler yüklenemedi.\n(${snapshot.error})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ));
                  }
                  // Veri başarıyla geldi durumu
                  else if (snapshot.hasData) {
                    final topRecipes =
                        snapshot.data!; // Gelen tarif listesi (RecipeModel)
                    // Veri boşsa mesaj göster
                    if (topRecipes.isEmpty) {
                      return const Center(
                          child: Text("Popüler tarif bulunamadı."));
                    }

                    // Veri geldiyse ve birden fazlaysa timer'ı başlat
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _startTimerIfNeeded(topRecipes.length);
                    });

                    // PageView ve Noktaları içeren Column
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // PageView
                        SizedBox(
                          height: MediaQuery.of(context).size.width *
                              (9 / 16) *
                              0.9, // Sadece PageView'ın yüksekliği
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: topRecipes.length,
                            onPageChanged: (int page) {
                              if (mounted) {
                                setState(() => _currentPage = page);
                              }
                              // Sayfa değişince timer'ı resetlemeye gerek yok, devam etsin
                            },
                            itemBuilder: (context, index) {
                              final recipe = topRecipes[index]; // RecipeModel
                              // Her bir banner öğesi
                              return InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipeDetailScreen(
                                        recipe: recipe), // RecipeModel gönder
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15.0),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Tarif Görseli
                                        Image.network(
                                          recipe.imageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                                  progress) =>
                                              progress == null
                                                  ? child
                                                  : Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  accentColor)),
                                          errorBuilder: (context, error,
                                                  stackTrace) =>
                                              Container(
                                                  color: Colors.grey[300],
                                                  alignment: Alignment.center,
                                                  child: Icon(
                                                      Icons.restaurant_menu,
                                                      color: Colors.grey[500],
                                                      size: 60)),
                                        ),
                                        // Alt Gradient
                                        Container(
                                            decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.black
                                                          .withAlpha(210)
                                                    ],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    stops: const [0.55, 1.0]))),
                                        // Tarif Başlığı
                                        Positioned(
                                          bottom: 15,
                                          left: 15,
                                          right: 15,
                                          child: Text(
                                            recipe.title,
                                            style: const TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                      blurRadius: 3,
                                                      color: Colors.black87)
                                                ]),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Sayfa Göstergesi (Noktalar)
                        if (topRecipes.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(topRecipes.length,
                                (index) => buildIndicator(index, context)),
                          ),
                      ],
                    );
                  }
                  // Diğer durumlar
                  else {
                    return const Center(
                        child: Text("Popüler tarif verisi bulunamadı."));
                  }
                },
              ),
            ),
          ),
          // ----------------------------------------------------------

          // --- Butonlar Bölümü (Stack ile Arka Planlı) ---
          // Bu kısım UI olarak aynı kalır, sadece onTap içindeki yönlendirmeler
          // API'ye bağlı ekranlara gitmeli (zaten öyle görünüyor)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: NetworkImage(backgroundImageUrl),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                                Colors.black45, BlendMode.darken)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.05 / 1,
                      children: [
                        _buildButtonItem(
                            context,
                            Icons.restaurant_menu_outlined,
                            'TARİFLER',
                            Colors.white,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => RecipesScreen(
                                          userId: 1,
                                        )))), // API'ye bağlı
                        _buildButtonItem(context, Icons.menu_book_outlined,
                            'MENÜLER', Colors.white,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const CategoriesScreen()))), // Kategoriler API'den gelmeli
                        _buildButtonItem(
                            context,
                            Icons.local_fire_department_outlined,
                            'TREND',
                            Colors.white,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const TrendingRecipesScreen()))), // API'ye bağlı
                        _buildButtonItem(context, Icons.timer_outlined,
                            'ZAMANLAYICI', Colors.white,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const GeneralTimerScreen()))),
                        _buildButtonItem(context, Icons.kitchen_outlined,
                            'NE PİŞİRSEM', Colors.white,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SelectIngredientsScreen()))), // API'ye bağlı
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ----------------------------------------------------------
          const SizedBox(height: 20), // En alta boşluk
        ],
      ),
    );
  }

  // Grid/Wrap Item oluşturan yardımcı metot (Buton)
  Widget _buildButtonItem(
      BuildContext context, IconData icon, String label, Color iconAndTextColor,
      {VoidCallback? onTap}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalHorizontalPadding = 32 + 32 + 24;
    final itemWidth = (screenWidth - totalHorizontalPadding) / 3;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: itemWidth.clamp(70, 100),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Colors.white.withOpacity(0.3), width: 0.5)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: iconAndTextColor),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  color: iconAndTextColor,
                  fontWeight: FontWeight.w600,
                  shadows: const [
                    Shadow(blurRadius: 1, color: Colors.black54)
                  ]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Sayfa göstergesi (nokta) oluşturan yardımcı metot
  Widget buildIndicator(int index, BuildContext context) {
    return Container(
      width: 8.0,
      height: 8.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 3.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? Theme.of(context).colorScheme.secondary
            : Colors.grey.shade400,
      ),
    );
  }
} // _HomeContentState sonu

// --- Placeholder Widget (Diğer sekmeler için) ---
class PlaceholderWidget extends StatelessWidget {
  final String title;
  const PlaceholderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                    '$title Ekranı İçeriği\nBurada ilgili özellikler yer alacak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18, color: Colors.grey[600], height: 1.5)))));
  }
}
// -------------------------------------------------
