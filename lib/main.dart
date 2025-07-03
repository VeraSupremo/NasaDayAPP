
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// --- MODELO DE DATOS ---
// Es una buena práctica tener una clase que represente la estructura de los datos de la API.
class Apod {
  final String title;
  final String explanation;
  final String date;
  final String url;
  final String mediaType;
  final String? copyright;

  Apod({
    required this.title,
    required this.explanation,
    required this.date,
    required this.url,
    required this.mediaType,
    this.copyright,
  });

  // Factory constructor para crear una instancia de Apod desde un mapa JSON.
  factory Apod.fromJson(Map<String, dynamic> json) {
    return Apod(
      title: json['title'] ?? 'Sin Título',
      explanation: json['explanation'] ?? 'Sin Explicación',
      date: json['date'] ?? '',
      url: json['hdurl'] ?? json['url'] ?? '',
      mediaType: json['media_type'] ?? 'image',
      copyright: json['copyright'],
    );
  }
}

// --- SERVICIO DE API ---
// Centraliza la lógica para comunicarte con la API de la NASA.
class ApiService {
  // NOTA: ¡Consigue tu propia API Key en https://api.nasa.gov/! 'DEMO_KEY' tiene limitaciones.
  static const String _apiKey = 'DEMO_KEY';
  static const String _baseUrl = 'https://api.nasa.gov/planetary/apod';

  Future<Apod> fetchApod({DateTime? date}) async {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String dateString = date != null ? formatter.format(date) : '';
    final Uri uri = Uri.parse('$_baseUrl?api_key=$_apiKey&date=$dateString');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        // Si la petición es exitosa, parsea el JSON.
        return Apod.fromJson(json.decode(response.body));
      } else {
        // Si el servidor responde con un error.
        throw Exception('Fallo al cargar los datos del APOD. Código: ${response.statusCode}');
      }
    } catch (e) {
      // Si ocurre un error en la petición (ej. sin internet).
      throw Exception('Fallo en la conexión: $e');
    }
  }
}

// --- APLICACIÓN PRINCIPAL ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Explorador Espacial',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey[900],
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade300,
          secondary: Colors.amber.shade300,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          elevation: 4,
        ),
      ),
      home: const ApodScreen(),
    );
  }
}


// --- PANTALLA PRINCIPAL ---
class ApodScreen extends StatefulWidget {
  const ApodScreen({super.key});

  @override
  State<ApodScreen> createState() => _ApodScreenState();
}

class _ApodScreenState extends State<ApodScreen> {
  late Future<Apod> futureApod;
  final ApiService apiService = ApiService();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Carga los datos del día actual al iniciar la pantalla.
    futureApod = apiService.fetchApod();
  }

  // Función para recargar los datos para una nueva fecha.
  void _loadApodForDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      futureApod = apiService.fetchApod(date: date);
    });
  }

  // Muestra el selector de fecha.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1995, 6, 16), // La primera fecha disponible en la API de APOD
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      _loadApodForDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto Astronómica del Día'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            tooltip: 'Seleccionar fecha',
          ),
        ],
      ),
      body: Center(
        // FutureBuilder es perfecto para manejar estados de carga/error/éxito de una Future.
        child: FutureBuilder<Apod>(
          future: futureApod,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Muestra un indicador de carga mientras se esperan los datos.
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              // Muestra un mensaje de error si algo falló.
              return Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              );
            } else if (snapshot.hasData) {
              // Si tenemos datos, construye la UI principal.
              final apod = snapshot.data!;
              return ApodDetailView(apod: apod);
            }
            // Estado por defecto (aunque no debería ocurrir en este flujo).
            return const Text('Inicia la exploración.');
          },
        ),
      ),
    );
  }
}

// --- WIDGET DE VISTA DE DETALLE ---
// Separa la vista del detalle para mantener el código más limpio.
class ApodDetailView extends StatelessWidget {
  final Apod apod;

  const ApodDetailView({super.key, required this.apod});
  
  // Función para abrir URLs.
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('No se pudo abrir $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            apod.title,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Fecha y Copyright
          Text(
            apod.date,
            style: textTheme.titleMedium?.copyWith(color: Colors.grey[400]),
          ),
          if (apod.copyright != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '© ${apod.copyright}',
                style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[500]),
              ),
            ),
          const SizedBox(height: 16),
          
          // Contenido multimedia (Imagen o Video)
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: apod.mediaType == 'image'
              ? Image.network(
                  apod.url,
                  fit: BoxFit.cover,
                  // Muestra un indicador de carga mientras la imagen se descarga.
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                     return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                  },
                )
              : GestureDetector(
                  onTap: () => _launchUrl(apod.url),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // En caso de video, podríamos mostrar una miniatura si la API la proveyera.
                      // Por ahora, un contenedor con un icono de play.
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          color: Colors.black,
                          child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 60),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        child: Text(
                          "Toca para ver el video",
                          style: textTheme.labelLarge
                        ),
                      )
                    ],
                  ),
                ),
          ),
          const SizedBox(height: 24),

          // Explicación
          Text(
            'Explicación',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            apod.explanation,
            style: textTheme.bodyMedium?.copyWith(height: 1.5), // Interlineado para mejor lectura
          ),
        ],
      ),
    );
  }
}
