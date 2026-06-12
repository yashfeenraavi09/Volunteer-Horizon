import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/survey_model.dart';
import '../core/providers.dart';

class SurveyHistoryScreen extends ConsumerWidget {
  const SurveyHistoryScreen({super.key});

  // Helper to map category to an icon
  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('health') || cat.contains('medical')) {
      return Icons.medical_services_rounded;
    } else if (cat.contains('infrastructure') || cat.contains('shelter') || cat.contains('damage')) {
      return Icons.construction_rounded;
    } else if (cat.contains('food') || cat.contains('water') || cat.contains('supply')) {
      return Icons.local_dining_rounded;
    } else if (cat.contains('safety') || cat.contains('security')) {
      return Icons.security_rounded;
    }
    return Icons.assignment_rounded;
  }

  // Helper to map severity to color scheme
  Color _getSeverityColor(String severity) {
    final sev = severity.toLowerCase();
    if (sev.contains('high') || sev.contains('critical') || sev.contains('severe')) {
      return Colors.red.shade700;
    } else if (sev.contains('medium') || sev.contains('moderate')) {
      return Colors.orange.shade700;
    }
    return Colors.green.shade700;
  }

  Color _getSeverityBgColor(String severity) {
    final sev = severity.toLowerCase();
    if (sev.contains('high') || sev.contains('critical') || sev.contains('severe')) {
      return Colors.red.shade50;
    } else if (sev.contains('medium') || sev.contains('moderate')) {
      return Colors.orange.shade50;
    }
    return Colors.green.shade50;
  }

  void _showSurveyDetails(BuildContext context, Survey survey) {
    final theme = Theme.of(context);
    final severityColor = _getSeverityColor(survey.severity);
    final severityBg = _getSeverityBgColor(survey.severity);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pill handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title and Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(survey.category),
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            survey.residentName.isEmpty ? 'Anonymous Resident' : survey.residentName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Detailed Survey Information
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailField('Children Count', child: Text(survey.childrenCount ?? 'N/A')),
                    _buildDetailField('Created At', child: Text(survey.createdAt != null ? survey.createdAt!.toLocal().toString().split('.').first.substring(0, 16) : 'N/A')),
                    _buildDetailField('Has Disability', child: Text(survey.hasDisability == true ? 'Yes' : 'No')),
                    _buildDetailField('House Type', child: Text(survey.houseType ?? 'N/A')),
                    _buildDetailField('Immunized', child: Text(survey.isImmunized == true ? 'Yes' : 'No')),
                    _buildDetailField('Resident Contact', child: Text(survey.residentContact ?? 'N/A')),
                    _buildDetailField('Social Group', child: Text(survey.socialGroup ?? 'N/A')),
                    _buildDetailField('Submitted By', child: Text(survey.submittedByVolunteerId ?? 'N/A')),
                    _buildDetailField('Toilet Access', child: Text(survey.toiletAccess ?? 'N/A')),
                    _buildDetailField('Total Members', child: Text(survey.totalMembers ?? 'N/A')),
                    _buildDetailField('Water Source', child: Text(survey.waterSource ?? 'N/A')),
                    _buildDetailField('Zone Label', child: Text(survey.zoneLabel ?? 'N/A')),
                  ],
                ),
                const SizedBox(height: 24),

                // Description Field
                _buildDetailField(
                  'Resident Feedback / Notes',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      survey.description.isEmpty ? 'No details or description provided.' : survey.description,
                      style: const TextStyle(
                        height: 1.5,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Close Details',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailField(String label, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surveysAsync = ref.watch(volunteerSurveysProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Survey History',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade200,
            height: 1.0,
          ),
        ),
      ),
      body: surveysAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Failed to load history',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        data: (surveys) => surveys.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 80,
                          color: theme.colorScheme.primary.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Surveys Found',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You haven\'t submitted any resident surveys yet. When you perform field surveys, they will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: surveys.length,
                itemBuilder: (context, index) {
                  final survey = surveys[index];
                  final severityColor = _getSeverityColor(survey.severity);
                  final severityBg = _getSeverityBgColor(survey.severity);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: severityColor,
                              width: 5,
                            ),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showSurveyDetails(context, survey),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(survey.category),
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                survey.residentName.isEmpty ? 'Anonymous Resident' : survey.residentName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: severityBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                survey.severity.toUpperCase(),
                                                style: TextStyle(
                                                  color: severityColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          survey.category,
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          survey.createdAt != null
                                              ? 'Submitted ${survey.createdAt!.toLocal().toString().split('.').first.substring(0, 16)}'
                                              : 'Date unknown',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.grey.shade400,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
