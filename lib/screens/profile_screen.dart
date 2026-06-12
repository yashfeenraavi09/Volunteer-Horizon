import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../core/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isAvailable = true;

  String _mapZone(String? rawZone) {
    if (rawZone == null) return 'Location not set';
    final zone = rawZone.toLowerCase();
    if (zone.contains('zone_1')) return 'Zone A';
    if (zone.contains('zone_2')) return 'Zone B';
    if (zone.contains('zone_3')) return 'Zone C';
    if (zone.contains('zone_4')) return 'Zone D';
    return rawZone;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(volunteerProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (userData) {
        final name = userData?.name ?? 'Guest Volunteer';
        final rawLocation = userData?.assignedZone ?? 'Location not set';
        final location = _mapZone(rawLocation);
        final phone = userData?.contact ?? 'Phone not set';
        final skills = (userData?.skills as List<dynamic>?)?.cast<String>() ?? [];
        final skillLevel = userData?.skillLevel ?? 'Verified';

        return Container(
          color: Colors.transparent,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  child: Column(
                    children: [
                      // Core Identity Sheet
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.primary.withOpacity(0.2),
                                        width: 3,
                                      ),
                                    ),
                                    child: const CircleAvatar(
                                      radius: 45,
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.person, size: 50, color: Colors.grey),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Upload Profile Picture')),
                                        );
                                      },
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                name,
                                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userData?.id ?? 'VOL-2026-XXXX',
                                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_user, color: theme.colorScheme.primary, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      userData?.utilizationStatus ?? 'Independent Volunteer',
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              const Divider(height: 1),
                              const SizedBox(height: 24),

                              // Availability Switch (Inline)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_filled,
                                        color: _isAvailable ? theme.colorScheme.primary : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Available Now',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _isAvailable,
                                    onChanged: (val) => setState(() => _isAvailable = val),
                                    activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
                                    activeThumbColor: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Compressed Detail Grid
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildMiniStat(Icons.location_on, 'Location', location),
                                  ),
                                  Expanded(
                                    child: _buildMiniStat(Icons.phone, 'Phone', phone),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Compressed Skills Section
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Icon(Icons.psychology, size: 20, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Skills ($skillLevel)',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.start,
                                children: skills.isEmpty
                                    ? [const Text('No skills listed')]
                                    : skills.map<Widget>((s) => _buildSoftChip(context, s)).toList(),
                              ),
                              const SizedBox(height: 24),
                              // Survey History Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/survey-history'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade50,
                                    foregroundColor: Colors.green.shade700,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Colors.green.shade100, width: 1),
                                    ),
                                  ),
                                  icon: const Icon(Icons.history_rounded),
                                  label: const Text('Survey History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Logout Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                                        content: const Text('Are you sure you want to sign out of Volunteer Hub?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context); // Close dialog
                                              await ref.read(authServiceProvider).signOut();
                                              if (context.mounted) {
                                                context.go('/login');
                                              }
                                            },
                                            child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    foregroundColor: Colors.red.shade700,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Colors.red.shade100, width: 1),
                                    ),
                                  ),
                                  icon: const Icon(Icons.logout_rounded),
                                  label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildSoftChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
