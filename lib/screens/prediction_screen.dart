import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/providers.dart';
import '../services/map_service.dart';

class PredictionZone {
  final String id;
  final String name;
  final String typeOfNeed;
  final int expectedPeople;
  final int volunteersRequired;
  final double confidenceScore;
  final gmaps.LatLng position;
  final String aiReasoning;
  final Color intensityColor;

  PredictionZone({
    required this.id,
    required this.name,
    required this.typeOfNeed,
    required this.expectedPeople,
    required this.volunteersRequired,
    required this.confidenceScore,
    required this.position,
    required this.aiReasoning,
    required this.intensityColor,
  });
}

class PredictionScreen extends ConsumerStatefulWidget {
  const PredictionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends ConsumerState<PredictionScreen> {
  gmaps.GoogleMapController? _mapController;
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapDataAsync = ref.watch(mapDataProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: mapDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
        data: (mapData) {
          final summary = mapData.summary;
          final hotspotName = summary['hotspot_zone'] ?? '';
          
          gmaps.LatLng initialCenter = const gmaps.LatLng(19.2183, 72.9781);
          if (mapData.reports.isNotEmpty) {
             final first = mapData.reports.first;
             initialCenter = gmaps.LatLng((first['latitude'] as num).toDouble(), (first['longitude'] as num).toDouble());
          }

          return Stack(
            children: [
              // 1. FULL SCREEN INTERACTIVE MAP
              Positioned.fill(
                child: gmaps.GoogleMap(
                  initialCameraPosition: gmaps.CameraPosition(target: initialCenter, zoom: 12),
                  markers: _buildAllMarkers(mapData),
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: gmaps.MapType.normal,
                ),
              ),

              // 2. TOP STATS OVERLAY
              Positioned(
                top: 20, left: 0, right: 0,
                child: _buildLiveStatsOverlay(mapData),
              ),

              // 3. HORIZONTAL CRISIS CAROUSEL
              Positioned(
                bottom: 120, left: 0, right: 0,
                child: SizedBox(
                  height: 150,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _moveMapToReport(mapData.reports[index]);
                    },
                    itemCount: mapData.reports.length,
                    itemBuilder: (context, index) {
                      return _buildHorizontalCrisisCard(mapData.reports[index], hotspotName, mapData);
                    },
                  ),
                ),
              ),

              // 4. AI INSIGHT BADGE (TOP RIGHT)
              Positioned(
                top: 120, right: 20,
                child: _buildAiInsightBadge(summary),
              ),
            ],
          );
        },
      ),
    );
  }

  void _moveMapToReport(dynamic report) {
    final lat = (report['latitude'] as num).toDouble();
    final lng = (report['longitude'] as num).toDouble();
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(lat, lng), 15),
    );
  }

  Widget _buildLiveStatsOverlay(MapData data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatText('FIELD VOLUNTEERS', '${data.volunteers.length}', Colors.green),
          _buildStatText('ACTIVE CRISIS', '${data.reports.length}', Colors.red),
          _buildStatText('PENDING TASKS', '${data.assignments.length}', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatText(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8, color: Colors.grey, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildAiInsightBadge(Map<String, dynamic> summary) {
    final hotspot = summary['hotspot_zone'] ?? 'SCANNING';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('PRIMARY HOTSPOT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 8)),
          Text(hotspot.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHorizontalCrisisCard(dynamic report, String activeHotspot, MapData allData) {
    final locationName = report['location_name'] ?? 'In-Field Incident';
    final description = report['text'] ?? report['description'] ?? report['details'] ?? 'Live incident reported in sector.';
    final bool isHotspot = locationName.toLowerCase().contains(activeHotspot.toLowerCase());

    return GestureDetector(
      onTap: () => _openFullCrisisMap(context, report, allData),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    locationName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, overflow: TextOverflow.ellipsis),
                  ),
                ),
                if (isHotspot)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                    child: const Text('HOTSPOT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Text('TAP FOR FULL DETAILS', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 14, color: Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Set<gmaps.Marker> _buildAllMarkers(MapData data) {
    final Set<gmaps.Marker> markers = {};
    for (var r in data.reports) {
      markers.add(gmaps.Marker(
        markerId: gmaps.MarkerId('r_${markers.length}'),
        position: gmaps.LatLng((r['latitude'] as num).toDouble(), (r['longitude'] as num).toDouble()),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
      ));
    }
    for (var v in data.volunteers) {
      markers.add(gmaps.Marker(
        markerId: gmaps.MarkerId('v_${markers.length}'),
        position: gmaps.LatLng((v['latitude'] as num).toDouble(), (v['longitude'] as num).toDouble()),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
      ));
    }
    return markers;
  }

  void _openFullCrisisMap(BuildContext context, dynamic report, MapData allData) {
    final lat = (report['latitude'] as num).toDouble();
    final lng = (report['longitude'] as num).toDouble();
    final description = report['text'] ?? report['description'] ?? 'Live incident reported in sector.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: gmaps.GoogleMap(
                initialCameraPosition: gmaps.CameraPosition(target: gmaps.LatLng(lat, lng), zoom: 16),
                markers: _buildAllMarkers(allData),
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
              ),
            ),
            Positioned(
              top: 20, right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.9)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 40, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CRITICAL FIELD LOG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.red)),
                    const SizedBox(height: 12),
                    Text(report['location_name'] ?? 'Incident', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(description, style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}