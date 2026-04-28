import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:geolocator/geolocator.dart';
import '../models/report_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiService {
  // Loads the key from --dart-define=GEMINI_KEY=...
  static const String _apiKey = String.fromEnvironment('GEMINI_KEY', defaultValue: 'YOUR_GEMINI_API_KEY_HERE');
  
  final GenerativeModel _model;

  AiService() : _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

  /// Checks if a new report is semantically similar to existing nearby reports
  Future<bool> isSemanticDuplicate(String newReportText, List<String> existingReportsText) async {
    if (existingReportsText.isEmpty) return false;
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') return false; // Fail safe if key is not set

    final prompt = '''
    Act as a deduplication assistant for an emergency response system. 
    Below is a new report description and a list of existing nearby reports.
    Decide if the new report is describing the SAME incident as any of the existing ones.
    
    New Report: "$newReportText"
    
    Existing Reports:
    ${existingReportsText.map((t) => "- $t").join('\n')}
    
    Respond with ONLY "DUPLICATE" if it's a match, or "UNIQUE" if it's a different incident.
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim().toUpperCase() == 'DUPLICATE';
    } catch (e) {
      print('AI Deduplication Error: $e');
      return false;
    }
  }

  /// Full Deduplication Logic: Geospatial + Temporal + AI Semantic
  Future<Report?> findDuplicate(String text, double lat, double lng, List<Report> recentReports) async {
    // 1. Geospatial check (50 meters)
    final nearbyReports = recentReports.where((report) {
      double distance = Geolocator.distanceBetween(
        lat, lng, 
        report.latitude, report.longitude
      );
      return distance < 50;
    }).toList();

    if (nearbyReports.isEmpty) return null;

    // 2. Semantic check using Gemini
    final texts = nearbyReports.map((r) => r.text).toList();
    bool isDuplicate = await isSemanticDuplicate(text, texts);

    if (isDuplicate) {
      // Return the most recent matching report
      return nearbyReports.first;
    }

    return null;
  }
}
