import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Tema durumu: true = Dark Mode, false = Light Mode
  bool _isDarkMode = false;

  // Tema değiştirme fonksiyonu
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gelişmiş Sayı Tahmin Oyunu',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: DifficultySelection(
        toggleTheme: _toggleTheme,
        isDarkMode: _isDarkMode,
      ),
    );
  }
}

class DifficultySelection extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  DifficultySelection({required this.toggleTheme, required this.isDarkMode});

  void _startGame(BuildContext context, String difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NumberGuessGame(
          difficulty: difficulty,
          toggleTheme: toggleTheme,
          isDarkMode: isDarkMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.teal[50]
          : Colors.grey[900],
      appBar: AppBar(
        title: Text('Sayı Tahmin Oyunu - Seçim Yap'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: toggleTheme,
            tooltip: isDarkMode ? 'Aydınlık Tema' : 'Karanlık Tema',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Seviye Seçiniz',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _startGame(context, 'Kolay'),
                child: Text('Kolay'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50), backgroundColor: Colors.green,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _startGame(context, 'Orta'),
                child: Text('Orta'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50), backgroundColor: Colors.orange,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _startGame(context, 'Zor'),
                child: Text('Zor'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50), backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NumberGuessGame extends StatefulWidget {
  final String difficulty;
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  NumberGuessGame({
    required this.difficulty,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  _NumberGuessGameState createState() => _NumberGuessGameState();
}

class _NumberGuessGameState extends State<NumberGuessGame>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late int _randomNumber;
  String _message = 'Tahmininizi girin!';
  List<int> _guessHistory = [];
  int _attempts = 0;
  late int _maxAttempts;
  bool _isGameOver = false;
  int _score = 0;
  late int _timeLimit; // Zaman sınırı saniye cinsinden
  late Timer _timer;
  int _remainingTime = 0;

  // Animasyon Kontrolcüsü
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _setGameParameters();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _startTimer();
  }

  void _setGameParameters() {
    switch (widget.difficulty) {
      case 'Kolay':
        _randomNumber = Random().nextInt(50) + 1; // 1-50
        _maxAttempts = 15;
        _timeLimit = 120; // 2 dakika
        break;
      case 'Orta':
        _randomNumber = Random().nextInt(100) + 1; // 1-100
        _maxAttempts = 10;
        _timeLimit = 90; // 1.5 dakika
        break;
      case 'Zor':
        _randomNumber = Random().nextInt(200) + 1; // 1-200
        _maxAttempts = 8;
        _timeLimit = 60; // 1 dakika
        break;
      default:
        _randomNumber = Random().nextInt(100) + 1;
        _maxAttempts = 10;
        _timeLimit = 90;
    }
    _remainingTime = _timeLimit;
    _message = '1 ile ${_getMaxNumber()} arasında bir sayı tahmin edin!';
  }

  int _getMaxNumber() {
    switch (widget.difficulty) {
      case 'Kolay':
        return 50;
      case 'Orta':
        return 100;
      case 'Zor':
        return 200;
      default:
        return 100;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime <= 0) {
        _endGame(timeOut: true);
      } else {
        setState(() {
          _remainingTime--;
        });
      }
    });
  }

  void _endGame({bool timeOut = false}) {
    _timer.cancel();
    setState(() {
      _isGameOver = true;
      if (timeOut) {
        _message =
            'Süreniz doldu! Maalesef kaybettiniz. Doğru sayı $_randomNumber idi.';
      } else if (_attempts >= _maxAttempts) {
        _message =
            'Deneme hakkınız bitti! Maalesef kaybettiniz. Doğru sayı $_randomNumber idi.';
      } else {
        _message = 'Tebrikler! Doğru tahmin ettiniz!';
        _score += (_maxAttempts - _attempts + 1) * 10;
      }
    });
    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    if (_timer.isActive) _timer.cancel();
    super.dispose();
  }

  void _checkGuess() {
    if (_isGameOver) return;

    int guess = int.tryParse(_controller.text) ?? -1;

    if (guess < 1 || guess > _getMaxNumber()) {
      setState(() {
        _message = 'Lütfen 1 ile ${_getMaxNumber()} arasında bir sayı girin.';
      });
      return;
    }

    setState(() {
      _attempts += 1;
      _guessHistory.add(guess);

      if (guess < _randomNumber) {
        _message = 'Daha yüksek bir sayı deneyin!';
      } else if (guess > _randomNumber) {
        _message = 'Daha düşük bir sayı deneyin!';
      } else {
        _endGame();
        return;
      }

      if (_attempts >= _maxAttempts) {
        _endGame();
      }

      _controller.clear();
      _animationController.forward(from: 0.0);
    });
  }

  void _resetGame() {
    if (_timer.isActive) _timer.cancel();
    setState(() {
      _randomNumber = Random().nextInt(100) + 1;
      _message = 'Yeni oyunda 1 ile ${_getMaxNumber()} arasında bir sayı tahmin edin!';
      _guessHistory.clear();
      _attempts = 0;
      _isGameOver = false;
      _score = 0;
      _setGameParameters();
    });
    _animationController.reset();
    _startTimer();
  }

  void _restartGame() {
    if (_timer.isActive) _timer.cancel();
    setState(() {
      _guessHistory.clear();
      _attempts = 0;
      _isGameOver = false;
      _score = 0;
      _setGameParameters();
    });
    _animationController.reset();
    _startTimer();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sayı Tahmin Oyunu - ${widget.difficulty} Seviye'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: 'Oyunu Sıfırla',
          ),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: widget.toggleTheme,
            tooltip: widget.isDarkMode ? 'Aydınlık Tema' : 'Karanlık Tema',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Zamanlayıcı ve Seviye Bilgisi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Zamanlayıcı
                Row(
                  children: [
                    Icon(Icons.timer, color: Colors.red),
                    SizedBox(width: 5),
                    Text(
                      _formatTime(_remainingTime),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                // Seviye Bilgisi
                Row(
                  children: [
                    Icon(Icons.category, color: Colors.blue),
                    SizedBox(width: 5),
                    Text(
                      widget.difficulty + ' Seviye',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            // Mesaj
            FadeTransition(
              opacity: _animation,
              child: Text(
                _message,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isGameOver
                      ? Colors.red
                      : Theme.of(context).brightness == Brightness.light
                          ? Colors.teal[800]
                          : Colors.teal[200],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            // Tahmin Girişi
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Tahmininizi girin',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _checkGuess(),
              enabled: !_isGameOver,
            ),
            SizedBox(height: 20),
            // Tahmin Et Butonu
            ElevatedButton(
              onPressed: _isGameOver ? null : _checkGuess,
              child: Text('Tahmin Et'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 20),
            // Tahmin Geçmişi ve Skor
            Expanded(
              child: Row(
                children: [
                  // Tahmin Geçmişi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tahmin Geçmişi:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.light
                                  ? Colors.teal[50]
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _guessHistory.isEmpty
                                ? Center(child: Text('Henüz tahmin yapılmadı.'))
                                : ListView.builder(
                                    itemCount: _guessHistory.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        leading: Icon(Icons.history,
                                            color: Theme.of(context).primaryColor),
                                        title: Text(
                                          'Tahmin ${index + 1}: ${_guessHistory[index]}',
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  // Skor
                  Container(
                    width: 100,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.teal[100]
                          : Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Skor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '$_score',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.light
                                ? Colors.teal[800]
                                : Colors.teal[200],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            // Deneme ve Skor Bilgisi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deneme: $_attempts / $_maxAttempts',
                  style: TextStyle(fontSize: 16),
                ),
                // Skor zaten üst kısımda gösteriliyor
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: _isGameOver
          ? FloatingActionButton(
              onPressed: _restartGame,
              child: Icon(Icons.replay),
              tooltip: 'Oyunu Yeniden Başlat',
            )
          : null,
    );
  }
}
