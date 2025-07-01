import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/apod_data.dart';  

Future<ApodData> fetchApod() async {
  final apiKey = 'DEMO_KEY'; // reeemplazar por la key propia
  final url = Uri.parse('https://api.nasa.gov/planetary/apod?api_key=$apiKey');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    return ApodData.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load APOD data');
  }
}