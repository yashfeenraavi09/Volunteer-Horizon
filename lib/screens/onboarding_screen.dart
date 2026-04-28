import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/custom_primary_button.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _cityController = TextEditingController();
  bool _isLocating = false;

  final List<String> _selectedSkills = ['Teaching'];
  final TextEditingController _otherSkillController = TextEditingController();
  bool _showOtherSkillInput = false;

  Set<String> _skillLevel = {'Beginner'}; // For SegmentedButton

  final List<String> _selectedTasks = ['Education'];

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  String _assignedZone = 'zone_1'; // New required field

  void _finishOnboarding({String redirectTo = '/home'}) async {
    setState(() => _isLocating = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      if (email.isEmpty || password.isEmpty) throw Exception("Email and Password cannot be empty.");

      // 1. Create authenticated user
      final userCredential = await ref.read(authServiceProvider).signUpWithEmail(email, password);
      final uid = userCredential?.user?.uid;
      
      if (uid != null) {
        // 2. Dual-Write Transaction (to 'volunteers' and 'volunteer_users')
        await ref.read(databaseServiceProvider).createVolunteerProfile(
          uid: uid,
          name: name,
          phone: phone,
          assignedZone: _assignedZone,
          skillType: _selectedSkills.isNotEmpty ? _selectedSkills.first.toLowerCase() : 'general',
        );
        
        if (mounted) context.go(redirectTo);
      }
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _cityController.text = '${place.locality ?? place.subAdministrativeArea}, ${place.country}';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            if (_currentPage > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () {
                        _pageController.previousPage(duration: 300.ms, curve: Curves.easeOut);
                      },
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_currentPage) / 6,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ).animate(target: _currentPage.toDouble()).shimmer(),
                    ),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
              ).animate().fade().slideY(begin: -1, end: 0),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildWelcomePage(),
                  _buildBasicInfoPage(),
                  _buildLocationPage(),
                  _buildSkillsPage(),
                  _buildAvailabilityPage(),
                  _buildPreferencesPage(),
                  _buildCompletionPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 0: Welcome ---
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hub_outlined, size: 120, color: Color(0xFF2E7D32))
              .animate()
              .fade(duration: 500.ms)
              .scale(delay: 200.ms),
          const SizedBox(height: 48),
          Text(
            'Create Your Profile',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ).animate().fade(delay: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),
          Text(
            'Set up your volunteer profile to get intelligently matched with local needs.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600, height: 1.5),
            textAlign: TextAlign.center,
          ).animate().fade(delay: 500.ms).slideY(begin: 0.2),
          const Spacer(),
          CustomPrimaryButton(
            text: 'Start Onboarding',
            icon: Icons.arrow_forward_rounded,
            onPressed: _nextPage,
          ).animate().fade(delay: 700.ms).slideY(begin: 0.5),
        ],
      ),
    );
  }

  // --- Step 1: Basic Info ---
  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Basic Info', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))
              .animate().fade().slideX(begin: -0.1),
          const SizedBox(height: 8),
          Text('Tell us a bit about yourself', style: TextStyle(color: Colors.grey.shade600))
              .animate().fade(delay: 100.ms).slideX(begin: -0.1),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
          ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
          ).animate().fade(delay: 250.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
            obscureText: true,
          ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
            keyboardType: TextInputType.phone,
          ).animate().fade(delay: 350.ms).slideY(begin: 0.1),
          const SizedBox(height: 32),
          CustomPrimaryButton(text: 'Continue', onPressed: _nextPage)
              .animate().fade(delay: 400.ms),
        ],
      ),
    );
  }

  // --- Step 2: Location ---
  Widget _buildLocationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Location', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))
              .animate().fade().slideX(begin: -0.1),
          const SizedBox(height: 8),
          Text('Where are you based?', style: TextStyle(color: Colors.grey.shade600))
              .animate().fade(delay: 100.ms).slideX(begin: -0.1),
          const SizedBox(height: 32),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'City / Region', prefixIcon: Icon(Icons.location_city)),
          ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _isLocating ? null : _getCurrentLocation,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
            icon: _isLocating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            label: const Text('Use My Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
          const SizedBox(height: 32),
          
          Text('Primary Coordination Zone', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))
              .animate().fade(delay: 400.ms),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _assignedZone,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              prefixIcon: const Icon(Icons.map_outlined),
            ),
            onChanged: (val) => setState(() => _assignedZone = val!),
            items: ['zone_1', 'zone_2', 'zone_3', 'zone_4'].map((z) => DropdownMenuItem(
              value: z,
              child: Text(z.split('_').join(' ').toUpperCase()),
            )).toList(),
          ).animate().fade(delay: 500.ms).slideY(begin: 0.1),

          const SizedBox(height: 48),
          CustomPrimaryButton(text: 'Continue', onPressed: _nextPage)
              .animate().fade(delay: 600.ms),
        ],
      ),
    );
  }

  // --- Step 3: Skills ---
  Widget _buildSkillsPage() {
    final defaultSkills = ['Teaching', 'First Aid', 'Driving', 'Cooking', 'Logistics'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your Skills', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))
              .animate().fade().slideX(begin: -0.1),
          const SizedBox(height: 8),
          Text('Select what you are good at', style: TextStyle(color: Colors.grey.shade600))
              .animate().fade(delay: 100.ms).slideX(begin: -0.1),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...defaultSkills.map((s) {
                final isSelected = _selectedSkills.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      val ? _selectedSkills.add(s) : _selectedSkills.remove(s);
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }),
              ActionChip(
                label: const Text('Other +', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => _showOtherSkillInput = !_showOtherSkillInput),
                backgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ],
          ).animate().fade(delay: 200.ms),
          if (_showOtherSkillInput) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _otherSkillController,
              decoration: InputDecoration(
                labelText: 'Specify Skill',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    if (_otherSkillController.text.isNotEmpty) {
                      setState(() {
                        _selectedSkills.add(_otherSkillController.text);
                        _otherSkillController.clear();
                        _showOtherSkillInput = false;
                      });
                    }
                  },
                ),
              ),
            ).animate().fade().slideY(begin: 0.2),
          ],
          const SizedBox(height: 48),
          Text('Overall Skill Level', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))
              .animate().fade(delay: 300.ms),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Beginner', label: Text('Beginner')),
              ButtonSegment(value: 'Intermediate', label: Text('Intermediate')),
              ButtonSegment(value: 'Expert', label: Text('Expert')),
            ],
            selected: _skillLevel,
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _skillLevel = newSelection);
            },
            style: ButtonStyle(
              padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 20)),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 32),
          CustomPrimaryButton(text: 'Continue', onPressed: _nextPage).animate().fade(delay: 500.ms),
        ],
      ),
    );
  }

  // --- Step 4: Availability ---
  Widget _buildAvailabilityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Availability', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))
              .animate().fade().slideX(begin: -0.1),
          const SizedBox(height: 8),
          Text('When can you help?', style: TextStyle(color: Colors.grey.shade600))
              .animate().fade(delay: 100.ms).slideX(begin: -0.1),
          const SizedBox(height: 32),
          _buildHoverTile('Always Available', Icons.all_inclusive).animate().fade(delay: 200.ms).slideX(),
          const SizedBox(height: 16),
          _buildHoverTile('Only in Emergencies', Icons.warning_amber_rounded).animate().fade(delay: 300.ms).slideX(),
          const SizedBox(height: 16),
          _buildHoverTile('Weekends', Icons.calendar_month).animate().fade(delay: 400.ms).slideX(),
          const SizedBox(height: 48),
          CustomPrimaryButton(text: 'Continue', onPressed: _nextPage).animate().fade(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildHoverTile(String title, IconData icon) {
    return StatefulBuilder(builder: (context, setStateSB) {
      bool isHovered = false;
      return MouseRegion(
        onEnter: (_) => setStateSB(() => isHovered = true),
        onExit: (_) => setStateSB(() => isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: isHovered ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: isHovered ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)] : [],
          ),
          child: CheckboxListTile(
            title: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            value: false, // Make stateful in real scenario
            onChanged: (v) {},
            contentPadding: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    });
  }

  // --- Step 5: Task Preferences ---
  Widget _buildPreferencesPage() {
    final tasks = [
      {'name': 'Education', 'icon': Icons.school},
      {'name': 'Food Dist', 'icon': Icons.restaurant},
      {'name': 'Medical', 'icon': Icons.medical_services},
      {'name': 'Environment', 'icon': Icons.park},
      {'name': 'Logistics', 'icon': Icons.local_shipping},
      {'name': 'Other / Any', 'icon': Icons.more_horiz},
    ];

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Task Preferences', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))
              .animate().fade(),
          const SizedBox(height: 8),
          Text('Select the types of tasks you prefer.', style: TextStyle(color: Colors.grey.shade600))
              .animate().fade(delay: 100.ms),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final isSelected = _selectedTasks.contains(task['name']);
                return InkWell(
                  onTap: () {
                    setState(() {
                      isSelected ? _selectedTasks.remove(task['name']) : _selectedTasks.add(task['name'] as String);
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(task['icon'] as IconData, size: 40, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade500),
                        const SizedBox(height: 12),
                        Text(
                          task['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fade(delay: (200 + index * 100).ms).scale();
              },
            ),
          ),
          CustomPrimaryButton(text: 'Complete Profile', onPressed: _nextPage).animate().fade(delay: 600.ms),
        ],
      ),
    );
  }

  // --- Step 6: Completion ---
  Widget _buildCompletionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.greenAccent, blurRadius: 30, spreadRadius: 5),
              ],
            ),
            child: const Icon(Icons.check, size: 80, color: Colors.white),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 48),
          Text(
            'You are all set!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),
          // ID Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.grey.shade800, Colors.black]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Row(
              children: [
                const Icon(Icons.badge, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VOLUNTEER ID', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    const Text('VOL-2026-4587', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ],
                ),
              ],
            ),
          ).animate().fade(delay: 500.ms).slideY(begin: 0.2),
          const SizedBox(height: 32),
          Text(
            'Independent Volunteer (Unverified)',
            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
          ).animate().fade(delay: 700.ms),
          const SizedBox(height: 32),
          CustomPrimaryButton(
            text: 'Join an Organization',
            isLoading: _isLocating,
            onPressed: () => _finishOnboarding(redirectTo: '/organization-join'),
          ).animate().fade(delay: 900.ms),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLocating ? null : () => _finishOnboarding(),
            child: Text(
              'Skip for now',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ).animate().fade(delay: 1100.ms),
        ],
      ),
    );
  }
}
