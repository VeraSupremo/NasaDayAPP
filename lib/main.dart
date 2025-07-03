
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- PASO 1: Añade estas dependencias en tu archivo pubspec.yaml ---
//
// dependencies:
//   flutter:
//     sdk: flutter
//   http: ^1.2.1
//   intl: ^0.19.0
//   shared_preferences: ^2.2.3
//   url_launcher: ^6.2.6
//   share_plus: ^9.0.0
//   google_fonts: ^6.2.1

// --- MODELO DE DATOS ---
class Apod {
  final String date;
  final String title;
  final String explanation;
  final String url;
  final String? hdurl;
  final String mediaType;
  final String? copyright;

  Apod({
    required this.date,
    required this.title,
    required this.explanation,
    required this.url,
    this.hdurl,
    required this.mediaType,
    this.copyright,
  });

  factory Apod.fromJson(Map<String, dynamic> json) {
    return Apod(
      date: json['date'],
      title: json['title'],
      explanation: json['explanation'],
      url: json['url'],
      hdurl: json['hdurl'],
      mediaType: json['media_type'],
      copyright: json['copyright'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'title': title,
      'explanation': explanation,
      'url': url,
      'hdurl': hdurl,
      'media_type': mediaType,
      'copyright': copyright,
    };
  }
}

// --- SERVICIO DE API ---
class ApiService {
  static const String _apiKey = 'DEMO_KEY'; // ¡Usa tu propia API Key!
  static const String _baseUrl = 'https://api.nasa.gov/planetary/apod';

  Future<Apod> fetchApod({String? date}) async {
    final String dateQuery = date != null ? '&date=$date' : '';
    final Uri uri = Uri.parse('$_baseUrl?api_key=$_apiKey$dateQuery');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return Apod.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['msg'] ?? 'Fallo al cargar los datos del APOD.');
    }
  }

  Future<Apod> fetchRandomApod() async {
    final Uri uri = Uri.parse('$_baseUrl?api_key=$_apiKey&count=1');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return Apod.fromJson(json.decode(response.body)[0]);
    } else {
      throw Exception('Fallo al cargar un APOD aleatorio.');
    }
  }
}

// --- APLICACIÓN PRINCIPAL ---
void main() async {
   WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Explorador Espacial',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB), // bg-gray-50
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87),
          titleTextStyle: GoogleFonts.inter(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const ApodHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- PANTALLA PRINCIPAL ---
class ApodHomePage extends StatefulWidget {
  const ApodHomePage({super.key});

  @override
  State<ApodHomePage> createState() => _ApodHomePageState();
}

class _ApodHomePageState extends State<ApodHomePage> {
  final ApiService _apiService = ApiService();
  Future<Apod>? _currentApodFuture;
  List<Apod> _favorites = [];
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _fetchTodaysApod();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _fetchTodaysApod() {
    setState(() {
      _showFavorites = false;
      _currentApodFuture = _apiService.fetchApod();
    });
  }

  void _fetchApodForDate(DateTime date) {
    setState(() {
      _showFavorites = false;
      _currentApodFuture = _apiService.fetchApod(date: _formatDate(date));
    });
  }

  void _fetchRandomApod() {
    setState(() {
      _showFavorites = false;
      _currentApodFuture = _apiService.fetchRandomApod();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1995, 6, 16),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _fetchApodForDate(picked);
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favsString = prefs.getStringList('apodFavorites') ?? [];
    setState(() {
      _favorites = favsString
          .map((s) => Apod.fromJson(json.decode(s)))
          .toList();
    });
  }

  Future<void> _toggleFavorite(Apod apod) async {
    final prefs = await SharedPreferences.getInstance();
    final isFavorite = _favorites.any((fav) => fav.date == apod.date);

    if (isFavorite) {
      _favorites.removeWhere((fav) => fav.date == apod.date);
    } else {
      _favorites.add(apod);
    }

    List<String> favsString = _favorites.map((fav) => json.encode(fav.toJson())).toList();
    await prefs.setStringList('apodFavorites', favsString);
    setState(() {}); // Para refrescar la UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Explorador Espacial'),
              centerTitle: true,
              floating: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildControlPanel(),
                    const SizedBox(height: 20),
                    _buildContentView(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          ElevatedButton.icon(
            onPressed: () => _selectDate(context),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text('Fecha'),
          ),
          ElevatedButton.icon(
            onPressed: _fetchTodaysApod,
            icon: const Icon(Icons.today, size: 16),
            label: const Text('Hoy'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
          ),
          ElevatedButton.icon(
            onPressed: _fetchRandomApod,
            icon: const Icon(Icons.shuffle, size: 16),
            label: const Text('Sorpréndeme'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700),
          ),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showFavorites = true),
            icon: const Icon(Icons.favorite, size: 16),
            label: const Text('Favoritos'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    if (_showFavorites) {
      return _buildFavoritesGrid();
    } else {
      return FutureBuilder<Apod>(
        future: _currentApodFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(heightFactor: 5, child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            );
          }
          if (snapshot.hasData) {
            final apod = snapshot.data!;
            final isFavorite = _favorites.any((fav) => fav.date == apod.date);
            return _buildApodDetail(apod, isFavorite);
          }
          return const Center(child: Text('No se pudo cargar la información.'));
        },
      );
    }
  }

  Widget _buildApodDetail(Apod apod, bool isFavorite) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMediaViewer(apod),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(apod.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.yMMMMd('es_ES').format(DateTime.parse(apod.date)),
                             // DateFormat.yMMMMd()
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 30,
                        ),
                        onPressed: () => _toggleFavorite(apod),
                      ),
                    ],
                  ),
                  if (apod.copyright != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('© ${apod.copyright}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Share.share('Echa un vistazo a esta foto de la NASA: ${apod.title}\n${apod.hdurl ?? apod.url}'),
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Compartir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Explicación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(apod.explanation, style: const TextStyle(fontSize: 15, height: 1.5), textAlign: TextAlign.justify),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMediaViewer(Apod apod) {
    if (apod.mediaType == 'image') {
      return Image.network(
        apod.url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 48)),
          );
        },
      );
    } else {
      return GestureDetector(
        onTap: () async {
          final uri = Uri.parse(apod.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.play_circle_outline, color: Colors.white, size: 60),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildFavoritesGrid() {
    if (_favorites.isEmpty) {
      return const Center(
        heightFactor: 5,
        child: Text('Aún no has guardado ningún favorito.'),
      );
    }
    
    final sortedFavorites = List<Apod>.from(_favorites)..sort((a,b) => b.date.compareTo(a.date));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: sortedFavorites.length,
      itemBuilder: (context, index) {
        final fav = sortedFavorites[index];
        return GestureDetector(
          onTap: () => _fetchApodForDate(DateTime.parse(fav.date)),
          child: GridTile(
            footer: GridTileBar(
              backgroundColor: Colors.black45,
              title: Text(fav.title, style: const TextStyle(fontSize: 12)),
              subtitle: Text(fav.date, style: const TextStyle(fontSize: 10)),
            ),
            child: fav.mediaType == 'image'
              ? Image.network(fav.url, fit: BoxFit.cover)
              : Container(color: Colors.black, child: const Icon(Icons.videocam, color: Colors.white)),
          ),
        );
      },
    );
  }
}


//</immersive\>