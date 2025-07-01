import 'package:flutter/material.dart';
import '../models/apod_data.dart';
import '../services/nasa_api.dart';

class ApodPage extends StatefulWidget {
  const ApodPage({super.key}); 

  @override
  State<ApodPage> createState() => _ApodPageState();
}

class _ApodPageState extends State<ApodPage> {
  late Future<ApodData> futureApod;

  @override
  void initState() {
    super.initState();
    futureApod = fetchApod();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NASA Picture of the Day'),
      ),
      body: Center(
        child: FutureBuilder<ApodData>(
          future: futureApod,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              final apod = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      apod.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Image.network(
                      apod.url,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'No se pudo cargar la imagen.\nPuede que el servidor no permita mostrarla en navegador.',
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(apod.explanation),
                  ],
                ),
              );
            } else {
              return const Text('No data');
            }
          },
        ),
      ),
    );
  }
}
