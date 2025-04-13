// lib/screens/general_timer_screen.dart (YENİ DOSYA)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GeneralTimerScreen extends StatefulWidget {
  const GeneralTimerScreen({super.key});

  @override
  State<GeneralTimerScreen> createState() => _GeneralTimerScreenState();
}

class _GeneralTimerScreenState extends State<GeneralTimerScreen> {
  final TextEditingController _timeController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;
  bool _timerStarted = false;
  int _initialDurationInSeconds = 0;

  @override
  void dispose() {
    _timeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Süreyi ayarlama fonksiyonu
  void _setTime() {
    final minutes = int.tryParse(_timeController.text);
    if (minutes != null && minutes > 0) {
      setState(() {
        _initialDurationInSeconds = minutes * 60;
        _resetTimer(resetDuration: true); // Ayarlayınca sıfırla
        FocusScope.of(context).unfocus(); // Klavyeyi kapat
      });
      print("Timer $_initialDurationInSeconds saniyeye ayarlandı.");
    } else {
      // Geçersiz giriş uyarısı
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lütfen geçerli bir dakika girin.'),
        backgroundColor: Colors.orange,
      ));
    }
  }

  // Timer'ı başlatma
  void _startTimer() {
    if (_isTimerRunning || _remainingSeconds <= 0) return;
    print("Genel zamanlayıcı başlatıldı.");
    _timerStarted = true;
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _isTimerRunning = false;
        setState(() {});
        print("Genel zamanlayıcı bitti.");
        _showTimerFinishedDialog();
      }
    });
    setState(() {}); // Başlat butonunun durumunu güncelle
  }

  // Timer'ı duraklatma
  void _pauseTimer() {
    if (!_isTimerRunning) return;
    print("Genel zamanlayıcı duraklatıldı.");
    _timer?.cancel();
    _isTimerRunning = false;
    setState(() {});
  }

  // Timer'ı sıfırlama
  void _resetTimer({bool resetDuration = true}) {
    print("Genel zamanlayıcı sıfırlandı.");
    _timer?.cancel();
    _isTimerRunning = false;
    _timerStarted = false;
    if (resetDuration && mounted) {
      setState(() {
        _remainingSeconds = _initialDurationInSeconds;
      });
    } else if (mounted) {
      // Sadece süreyi başa sar, ayarlanan süreyi değiştirme
      // Bu durum pek kullanılmaz ama yine de ekleyelim
      setState(() {
        _remainingSeconds = _initialDurationInSeconds;
      });
    }
  }

  // Süreyi MM:SS formatında gösterme
  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // Süre bitince gösterilecek dialog
  void _showTimerFinishedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Süre Doldu!"),
          content: const Text("Zamanlayıcı tamamlandı."),
          actions: <Widget>[
            TextButton(
              child: const Text("Tamam"),
              onPressed: () {
                Navigator.of(ctx).pop();
                // İsteğe bağlı: Süre bitince timer'ı otomatik sıfırla
                // _resetTimer();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Butonların aktiflik durumunu belirle
    bool canReset = _timerStarted ||
        (_initialDurationInSeconds > 0 &&
            _remainingSeconds != _initialDurationInSeconds);
    bool canPlayPause = _initialDurationInSeconds > 0 &&
        _remainingSeconds >= 0 &&
        !_isTimerRunning; // 0 olunca da başlatılabilsin (tekrar)
    bool canPause = _isTimerRunning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Genel Zamanlayıcı'),
      ),
      // Klavye açıldığında taşmayı önlemek için SingleChildScrollView
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0), // Daha fazla padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Süre Giriş Alanı
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: 'Süre (dakika)',
                hintText: 'Örn: 10',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                suffixIcon: IconButton(
                  // Ayarla butonu
                  icon: Icon(Icons.check_circle_outline, color: accentColor),
                  tooltip: 'Süreyi Ayarla',
                  onPressed: _setTime,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly, // Sadece rakam girişi
              ],
              onSubmitted: (_) => _setTime(), // Enter'a basınca da ayarla
            ),
            const SizedBox(height: 30.0),

            // Kalan Süre Göstergesi
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 15.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                _formatDuration(_remainingSeconds),
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isTimerRunning &&
                          _remainingSeconds < 11 &&
                          _remainingSeconds > 0 // Son 10 sn kırmızı
                      ? Colors.red.shade700
                      : Theme.of(context).primaryColor,
                  letterSpacing: 4.0, // Rakamlar arası boşluk
                  fontFamily: 'monospace', // Sabit genişlikli font
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 35.0),

            // Kontrol Butonları
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly, // Eşit aralıklarla dağıt
              children: [
                // Sıfırla Butonu
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  iconSize: 40, // Daha büyük ikonlar
                  color: canReset ? Colors.blueGrey[700] : Colors.grey[400],
                  tooltip: 'Sıfırla',
                  onPressed:
                      canReset ? () => _resetTimer(resetDuration: true) : null,
                ),

                // Başlat/Duraklat Butonu (Dinamik)
                IconButton.filled(
                  // Daha belirgin ana buton
                  style: IconButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.all(18), // Daha büyük buton alanı
                  ),
                  icon: Icon(
                    _isTimerRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  iconSize: 48, // En büyük ikon
                  tooltip: _isTimerRunning ? 'Duraklat' : 'Başlat',
                  onPressed: _isTimerRunning
                      ? _pauseTimer
                      : (canPlayPause
                          ? _startTimer
                          : null), // Duruma göre fonksiyon ata
                ),

                // Durdur Butonu (Sadece sıfırlama gibi, ama belki tamamen durdurmak için?)
                // Genellikle Reset yeterli olur. Şimdilik bunu eklemeyelim kafa karıştırmasın.
                // IconButton(
                //   icon: const Icon(Icons.stop_rounded),
                //   iconSize: 40,
                //   color: _timerStarted ? Colors.red[700] : Colors.grey[400],
                //   tooltip: 'Durdur ve Sıfırla',
                //   onPressed: _timerStarted ? () => _resetTimer(resetDuration: true) : null,
                // ),
                SizedBox(
                    width: 40) // Simetri için boşluk (eğer 3 buton olsaydı)
              ],
            ),
            const SizedBox(height: 20), // Alt boşluk
          ],
        ),
      ),
    );
  }
}
