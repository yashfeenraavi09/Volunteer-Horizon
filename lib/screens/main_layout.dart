import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import 'home_screen.dart';
import 'prediction_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PredictionScreen(),
    const ReportScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isHighPriority = ref.watch(highPriorityModeProvider);
    final theme = Theme.of(context);

    // Dynamic gradient color depending on the mode
    final topColor = theme.colorScheme.primary.withValues(alpha: 0.15);

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: const Alignment(0, -0.4), // Fades to white fairly high up before content
            colors: [
              topColor,
              Colors.white,
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Custom Floating Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VH',
                      style: GoogleFonts.poppins(
                        textStyle: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isHighPriority ? Colors.red.shade900 : const Color(0xFF1B5E20),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Priority Mode',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isHighPriority ? Colors.red.shade900 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 30, // Make the switch slightly smaller
                          child: FittedBox(
                            fit: BoxFit.fill,
                            child: Switch(
                              value: isHighPriority,
                              onChanged: (val) {
                                ref.read(highPriorityModeProvider.notifier).toggle(val);
                              },
                              activeColor: Colors.white,
                              activeTrackColor: Colors.red,
                              inactiveTrackColor: Colors.grey.shade300,
                              inactiveThumbColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Screen Content
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: theme.colorScheme.primaryContainer,
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12);
              }
              return const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal, fontSize: 12);
            }),
            iconTheme: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return IconThemeData(color: theme.colorScheme.primary);
              }
              return const IconThemeData(color: Colors.grey);
            }),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            height: 70,
            elevation: 0,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Insights'),
              NavigationDestination(icon: Icon(Icons.report_problem_outlined), selectedIcon: Icon(Icons.report_problem), label: 'Reports'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
