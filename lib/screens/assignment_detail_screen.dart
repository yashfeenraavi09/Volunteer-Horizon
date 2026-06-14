import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assignment_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../core/providers.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final Assignment assignment;
  const AssignmentDetailScreen({Key? key, required this.assignment}) : super(key: key);

  @override
  ConsumerState<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends ConsumerState<AssignmentDetailScreen> {
  bool _isActionLoading = false;

  Future<void> _handleAccept() async {
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;

    setState(() => _isActionLoading = true);
    final success = await ref.read(databaseServiceProvider).acceptAssignment(uid, widget.assignment.id);
    setState(() => _isActionLoading = false);

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to accept. Task might have been taken.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;

    setState(() => _isActionLoading = true);
    await ref.read(databaseServiceProvider).updateAssignmentStatus(widget.assignment.id, status, uid);
    setState(() => _isActionLoading = false);
    
    if (mounted && status == 'completed') {
      _showSuccessPopup();
    }
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
            SizedBox(height: 16),
            Text('Mission Complete!', textAlign: TextAlign.center),
          ],
        ),
        content: const Text(
          'Great work, volunteer! You have successfully completed this mission and helped the community.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to Home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('BACK TO HOME', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for real-time updates on the assignment document only.
    // mission_description is already on the assignment — no need to stream reports.
    final assignmentAsync = ref.watch(singleAssignmentProvider(widget.assignment.id));

    return assignmentAsync.when(
      data: (a) => _buildScaffold(a ?? widget.assignment),
      loading: () => _buildScaffold(widget.assignment, isLoading: true),
      error: (err, _) => _buildScaffold(widget.assignment, error: err.toString()),
    );
  }

  Widget _buildScaffold(Assignment a, {bool isLoading = false, String? error}) {
    final isPending = a.assignmentStatus == 'pending';
    final isAccepted = a.assignmentStatus == 'accepted';
    final isEnRoute = a.assignmentStatus == 'en_route';
    final isOnSite = a.assignmentStatus == 'on_site';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Control'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a.category.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Location Title
                    Text(
                      a.locationName, 
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 32),
                    
                    // Stats Grid
                    Row(
                      children: [
                        Expanded(child: _buildInfoCard(Icons.priority_high, 'Priority', 'Level ${a.priorityRank}')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInfoCard(Icons.location_on_outlined, 'Zone', a.zoneLabel)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Description Section
                    _buildSectionHeader('Mission Description'),
                    const SizedBox(height: 12),
                    Text(
                      a.missionDescription ?? 'No description available.',
                      style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 15),
                    ),
                    
                    const SizedBox(height: 32),
                    _buildSectionHeader('Mission Type'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.category_outlined, size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '${a.category[0].toUpperCase()}${a.category.substring(1)} Response',
                          style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isActionLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (isPending)
                    _buildMainButton('ACCEPT MISSION', _handleAccept, color: Theme.of(context).colorScheme.primary)
                  else ...[
                    if (isAccepted)
                      _buildMainButton('START TRAVEL', () => _updateStatus('en_route'), color: Colors.blue),
                    if (isEnRoute)
                      _buildMainButton('ARRIVED ON SITE', () => _updateStatus('on_site'), color: Colors.orange),
                    if (isOnSite)
                      _buildMainButton('MARK AS COMPLETED', () => _updateStatus('completed'), color: Colors.green),
                  ],
                  const SizedBox(height: 8), // Small padding at the very bottom
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.grey.shade500,
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildMainButton(String label, VoidCallback onPressed, {required Color color}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
      ),
    );
  }
}
