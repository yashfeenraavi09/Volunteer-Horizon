import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/providers.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'screens/organization_join_screen.dart';
import 'screens/survey_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    const ProviderScope(
      child: VolunteerApp(),
    ),
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/survey-history',
        builder: (context, state) => const SurveyHistoryScreen(),
      ),
      // Existing routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainLayout(),
      ),
      GoRoute(
        path: '/organization-join',
        builder: (context, state) => const OrganizationJoinScreen(),
      ),
    ],
  );
});

class VolunteerApp extends ConsumerWidget {
  const VolunteerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final isHighPriority = ref.watch(highPriorityModeProvider);

    return MaterialApp.router(
      title: 'Volunteer App',
      theme: isHighPriority ? AppTheme.highPriorityTheme : AppTheme.normalTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
