import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survey_camp/core/models/survey_model.dart';
import 'package:survey_camp/core/providers/auth_provider.dart';
import 'package:survey_camp/core/services/app_usage_monitor.dart';
import 'package:survey_camp/core/services/notification_service.dart';
import 'package:survey_camp/core/services/user_survey_service.dart';
import 'package:survey_camp/features/shop/shop_screen.dart';
import 'package:survey_camp/features/survey_page/survey_page.dart';
import 'package:survey_camp/shared/widgets/custom_navbar.dart';
import 'package:survey_camp/features/auth/login/login.dart';
import 'package:survey_camp/features/auth/splash_screen/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:survey_camp/shared/widgets/suggested_survey_popup.dart';
import 'package:usage_stats/usage_stats.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  try {
    await dotenv.load(fileName: 'lib/config/.env');
    print('Dotenv loaded successfully: ${dotenv.env}');
  } catch (e) {
    print('Failed to load .env file: $e');
  }
  await Firebase.initializeApp();

  SystemChannels.lifecycle.setMessageHandler((msg) async {
    if (msg == AppLifecycleState.paused.toString()) {
      NotificationService.scheduleBackgroundNotification();
    }
    return null;
  });

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Add this line
      debugShowCheckedModeBanner: false,
      title: 'Survey Camp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const AuthWrapper(),
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/navbar': (context) => const CustomBottomNavbar(),
        '/shop': (context) => const ShopScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  final UserSurveyService _surveyService = UserSurveyService();
  bool _hasCheckedSurvey = false;

  @override
  void initState() {
    super.initState();
    // Schedule survey check after the first frame, but only if auth resolves
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndSurvey();
    });
  }

  Future<void> _checkAuthAndSurvey() async {
    if (_hasCheckedSurvey || !mounted) return;

    setState(() {
      _hasCheckedSurvey = true;
    });

    print('Checking auth state and survey recommendation');
    final authState = ref.read(authProvider);
    authState.when(
      data: (user) async {
        if (user != null && mounted) {
          print('User authenticated, checking for survey recommendation');
          await _checkForSurveyRecommendation(context);
        }
      },
      loading: () {
        print('Auth still loading, waiting...');
      },
      error: (error, stack) {
        print('Auth error: $error');
      },
    );
  }

  Future<void> _checkForSurveyRecommendation(BuildContext context) async {
    print('Checking for survey recommendation in AuthWrapper');
    final suggestedSurvey = await _surveyService.checkAndGetSuggestedSurvey();
    print('Suggested survey result: $suggestedSurvey');

    if (suggestedSurvey != null && mounted) {
      print('Showing survey popup for survey: ${suggestedSurvey.title}');
      showDialog(
        context: context,
        builder: (context) {
          print('Building SuggestedSurveyPopup');
          return SuggestedSurveyPopup(
            survey: suggestedSurvey,
            onTakeSurvey: () {
              print('User chose to take survey: ${suggestedSurvey.title}');
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SurveyPage(
                    surveyId: suggestedSurvey.id,
                    categoryName: suggestedSurvey.categoryName,
                  ),
                ),
              );
            },
            onDismiss: () {
              print('User dismissed survey: ${suggestedSurvey.title}');
              Navigator.of(context).pop();
            },
          );
        },
      );
    } else {
      print('No suggested survey to show');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginPage();
        }
        return const CustomBottomNavbar();
      },
      loading: () => const SplashScreen(),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
