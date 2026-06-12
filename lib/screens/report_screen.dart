import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../core/providers.dart';
import '../services/ai_service.dart';
import '../models/report_model.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

enum ReportMode { form, picture }
enum TypeMode { disaster, survey }

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _aiService = AiService();
  bool _isSubmitting = false;
  // ... rest of state ...
  ReportMode _currentMode = ReportMode.form;
  TypeMode _selectedType = TypeMode.disaster;

  // Common Field Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  GeoPoint? _currentLocation;
  String? _capturedAddress;

  // Disaster Specific State
  String _disasterCategory = 'Medical';
  String _severity = 'Medium';
  final List<String> _resourceNeeds = [];

  // Population Survey Specific State (Indian Standard)
  final _headNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _totalMembersController = TextEditingController();
  final _childrenCountController = TextEditingController();
  String _socialGroup = 'General';
  String _houseType = 'Pucca';
  String _waterSource = 'Tap';
  String _toiletAccess = 'Individual';
  bool _hasDisability = false;
  bool _isImmunized = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _headNameController.dispose();
    _phoneController.dispose();
    _totalMembersController.dispose();
    _childrenCountController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      setState(() {
        _currentLocation = GeoPoint(position.latitude, position.longitude);
      });

      // Fetch human-readable address
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            _capturedAddress = "${p.name}, ${p.subLocality}, ${p.locality}";
          });
        }
      } catch (e) {
        debugPrint("Geocoding error: $e");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS Coordinates and Address fetched successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching location: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _submitReport() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final profile = ref.read(volunteerProfileProvider).value;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Volunteer profile not found!')),
      );
      return;
    }

    if (_selectedType == TypeMode.disaster) {
      if (_titleController.text.isEmpty || _descController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title and Description are required!'), backgroundColor: Colors.orange),
        );
        return;
      }
    } else {
      if (_headNameController.text.isEmpty || _phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and Contact are required for survey!'), backgroundColor: Colors.orange),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final String fullDescription = "${_titleController.text}\n\n${_descController.text}";
      final lat = _currentLocation?.latitude ?? 0.0;
      final lng = _currentLocation?.longitude ?? 0.0;

      if (_selectedType == TypeMode.disaster) {
        // 1. AI DEDUPLICATION CHECK
        final recentData = await ref.read(databaseServiceProvider).findRecentReports();
        final recentReports = recentData.map((d) => Report.fromFirestore(_mockDoc(d))).toList();
        
        final duplicate = await _aiService.findDuplicate(fullDescription, lat, lng, recentReports);
        
        if (duplicate != null) {
          bool? proceed = await _showDuplicateDialog(duplicate);
          if (proceed != true) {
            setState(() => _isSubmitting = false);
            return;
          }
        }

        // 2. PROCEED WITH SUBMISSION
        // Debug: print selected category
        debugPrint('Submitting report with category: \'${_disasterCategory}\'');
        await ref.read(databaseServiceProvider).submitReport(
          uid: user.uid,
          category: _disasterCategory,
          description: fullDescription,
          severity: _severity,
          lat: lat,
          lng: lng,
          locationName: _capturedAddress ?? "Auto-captured via Mobile App",
          zoneLabel: profile.assignedZone,
        );
      } else {
        // 3. SURVEY REDUNDANCY CHECK (Composite Key handled in service)
        await ref.read(databaseServiceProvider).submitSurvey(
          uid: user.uid,
          residentName: _headNameController.text,
          residentContact: _phoneController.text,
          zoneLabel: profile.assignedZone,
          surveyData: {
            'total_members': _totalMembersController.text,
            'children_count': _childrenCountController.text,
            'social_group': _socialGroup,
            'house_type': _houseType,
            'water_source': _waterSource,
            'toilet_access': _toiletAccess,
            'has_disability': _hasDisability,
            'is_immunized': _isImmunized,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data submitted successfully! Deduplication & Redundancy handled.')),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool?> _showDuplicateDialog(Report duplicate) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Similar Incident Nearby'),
          ],
        ),
        content: Text(
          'Our AI detected a similar report nearby: "${duplicate.text.split('\n').first}"\n\n'
          'Do you still want to submit this as a new incident, or should we link it to the existing one?'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('PROCEED ANYWAY')),
        ],
      ),
    );
  }

  void _resetForm() {
    _titleController.clear();
    _descController.clear();
    _headNameController.clear();
    _phoneController.clear();
    _totalMembersController.clear();
    _childrenCountController.clear();
    setState(() {
      _currentLocation = null;
      _capturedAddress = null;
    });
  }

  DocumentSnapshot _mockDoc(Map<String, dynamic> data) {
    final id = data.remove('id') ?? '';
    return _MockDocumentSnapshot(id, data);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Action Center',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submit verified field reports.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              // Compact Icon-only Mode Toggle (Form vs Picture)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SegmentedButton<ReportMode>(
                  segments: const [
                    ButtonSegment(
                      value: ReportMode.form,
                      icon: Icon(Icons.description_outlined, size: 20),
                    ),
                    ButtonSegment(
                      value: ReportMode.picture,
                      icon: Icon(Icons.camera_alt_outlined, size: 20),
                    ),
                  ],
                  selected: {_currentMode},
                  onSelectionChanged: (value) {
                    setState(() => _currentMode = value.first);
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.transparent,
                    selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                    selectedForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Report Type Selector (Disaster vs Survey)
          if (_currentMode == ReportMode.form) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTypeToggleItem(
                      title: 'Disaster',
                      icon: Icons.warning_amber_rounded,
                      isActive: _selectedType == TypeMode.disaster,
                      onTap: () => setState(() => _selectedType = TypeMode.disaster),
                    ),
                  ),
                  Expanded(
                    child: _buildTypeToggleItem(
                      title: 'Survey',
                      icon: Icons.people_outline,
                      isActive: _selectedType == TypeMode.survey,
                      onTap: () => setState(() => _selectedType = TypeMode.survey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // GPS Location Widget
          _buildLocationWidget(),

          const SizedBox(height: 32),

          // Conditional UI based on mode
          if (_currentMode == ReportMode.picture) 
            _buildPictureSection(context)
          else 
            _buildFormSection(context),

          const SizedBox(height: 32),

          if (_isSubmitting)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Syncing with NGO Dashboard...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _submitReport,
                icon: const Icon(Icons.send_rounded),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
                label: const Text('Submit Verified Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTypeToggleItem({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Location Tagging', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  _capturedAddress ?? (_currentLocation == null 
                      ? 'GPS coordinates not attached' 
                      : 'Locked: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _getCurrentLocation,
            child: const Text('Locate Me'),
          ),
        ],
      ),
    );
  }

  Widget _buildPictureSection(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_a_photo, size: 48, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Capture or Upload Picture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'AI will extract details from image',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(BuildContext context) {
    return Column(
      children: [
        _buildTextField(
          context,
          controller: _titleController,
          label: 'Report Title',
          hint: 'Short summary of the situation',
          icon: Icons.title,
        ),
        const SizedBox(height: 20),

        if (_selectedType == TypeMode.disaster)
          _buildDisasterFields()
        else
          _buildSurveyFields(),

        const SizedBox(height: 20),
        _buildTextField(
          context,
          controller: _descController,
          label: 'Contextual Observations',
          hint: 'Describe what you see on the ground...',
          icon: Icons.subject,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildDisasterFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Category',
                value: _disasterCategory,
                items: ['Medical', 'Flood', 'Fire', 'Infrastructure', 'Shortage'],
                onChanged: (val) => setState(() => _disasterCategory = val!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown(
                label: 'Severity',
                value: _severity,
                items: ['Low', 'Medium', 'High', 'Critical'],
                onChanged: (val) => setState(() => _severity = val!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSurveyFields() {
    return Column(
      children: [
        _buildTextField(
          context,
          controller: _headNameController,
          label: 'Head of Household',
          hint: 'Full Name of the resident',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          context,
          controller: _phoneController,
          label: 'Primary Phone Number',
          hint: '10-digit mobile number',
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                context,
                controller: _totalMembersController,
                label: 'Family Size',
                hint: 'Total members',
                icon: Icons.group,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                context,
                controller: _childrenCountController,
                label: 'Children (0-6)',
                hint: 'Lactating/Infants',
                icon: Icons.child_care,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Social Identity (Standard)',
          value: _socialGroup,
          items: ['General', 'OBC', 'SC', 'ST', 'Other'],
          onChanged: (val) => setState(() => _socialGroup = val!),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Housing Type',
                value: _houseType,
                items: ['Pucca', 'Semi-Pucca', 'Kutcha'],
                onChanged: (val) => setState(() => _houseType = val!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown(
                label: 'Water Source',
                value: _waterSource,
                items: ['Tap', 'Handpump', 'Well', 'Tanker'],
                onChanged: (val) => setState(() => _waterSource = val!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _MockDocumentSnapshot implements DocumentSnapshot {
  @override
  final String id;
  final Map<String, dynamic> _data;

  _MockDocumentSnapshot(this.id, this._data);

  @override
  Object? operator [](Object field) => _data[field];
  @override
  Map<String, dynamic> data() => _data;
  @override
  bool get exists => true;
  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
  @override
  DocumentReference get reference => throw UnimplementedError();
  @override
  dynamic get(Object field) => _data[field];
}
