import 'dart:convert';
import 'package:http/http.dart' as http;

class MapData {
  final List<dynamic> reports;
  final List<dynamic> assignments;
  final List<dynamic> volunteers;
  final Map<String, dynamic> summary;

  MapData({
    required this.reports,
    required this.assignments,
    required this.volunteers,
    required this.summary,
  });

  factory MapData.fromJson(Map<String, dynamic> json) {
    return MapData(
      reports: json['reports'] ?? [],
      assignments: json['assignments'] ?? [],
      volunteers: json['volunteers'] ?? [],
      summary: json['summary'] ?? {},
    );
  }
}

class MapService {
  static const String _url = 'https://asia-south1-ngo-dashboard-ade99.cloudfunctions.net/getMapData';

  Future<MapData> fetchMapData() async {
    try {
      final response = await http.get(Uri.parse(_url));
      if (response.statusCode == 200) {
        return MapData.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load map data');
      }
    } catch (e) {
      print('MapService Error: $e');
      rethrow;
    }
  }
}
