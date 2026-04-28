import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/custom_primary_button.dart';

class OrganizationJoinScreen extends StatefulWidget {
  const OrganizationJoinScreen({super.key});

  @override
  State<OrganizationJoinScreen> createState() => _OrganizationJoinScreenState();
}

class _OrganizationJoinScreenState extends State<OrganizationJoinScreen> {
  final TextEditingController _codeController = TextEditingController();

  final List<Map<String, String>> _mockOrgs = [
    {
      'name': 'Red Cross International',
      'desc': 'Global humanitarian network providing emergency assistance and disaster relief.',
    },
    {
      'name': 'Green Peace',
      'desc': 'Environmental organization focused on climate change and conservation.',
    },
    {
      'name': 'World Food Program',
      'desc': 'Leading humanitarian organization saving lives in emergencies.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => context.go('/home'),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Connect with an\nOrganization',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ).animate().fade().slideX(begin: -0.1),
                const SizedBox(height: 12),
                Text(
                  'Join an NGO to receive more targeted tasks and increase your impact',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ).animate().fade(delay: 200.ms).slideX(begin: -0.1),
                
                const SizedBox(height: 40),
                
                // Option 1: Join with Code
                _buildSectionTitle('Join with Code'),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: 'e.g. ORG-HELP-1234',
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
                    prefixIcon: const Icon(Icons.qr_code),
                  ),
                ).animate().fade(delay: 400.ms),
                const SizedBox(height: 16),
                CustomPrimaryButton(
                  text: 'Join Organization',
                  onPressed: () {
                    _showSuccessDialog('Red Cross International');
                  },
                ).animate().fade(delay: 500.ms),
                
                const SizedBox(height: 48),
                
                // Option 2: Browse
                _buildSectionTitle('Browse Organizations'),
                const SizedBox(height: 16),
                ..._mockOrgs.map((org) => _buildOrgCard(org)).toList(),
                
                const SizedBox(height: 32),
                
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Skip for Now',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildOrgCard(Map<String, String> org) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    org['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              org['desc']!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _showSuccessDialog(org['name']!);
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Request to Join'),
              ),
            ),
          ],
        ),
      ),
    ).animate().fade().slideY(begin: 0.1);
  }

  void _showSuccessDialog(String orgName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Join Request Sent',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Your request to join $orgName has been submitted. You will be notified once verified.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }
}
