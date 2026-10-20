import 'package:flutter/material.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/pin_setup_screen.dart';
import '../../presentation/screens/auth/pin_login_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/camera/camera_screen.dart' as camera;
import '../../presentation/screens/results/results_screen.dart';
import '../../presentation/screens/batch/batch_create_screen.dart';
import '../../presentation/screens/batch/batch_detail_screen.dart';
import '../../presentation/screens/batch/batch_history_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
        
      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
        
      case AppRoutes.pinSetup:
        return MaterialPageRoute(builder: (_) => const PinSetupScreen());
        
      case AppRoutes.pinLogin:
        return MaterialPageRoute(builder: (_) => const PinLoginScreen());
        
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
        
      case AppRoutes.camera:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => camera.CameraScreen(batchId: args?['batchId'] as String?),
          fullscreenDialog: true,
        );
        
      case AppRoutes.results:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ResultsScreen(scanId: args?['scanId']),
        );
        
      case AppRoutes.batchCreate:
        return MaterialPageRoute(builder: (_) => const BatchCreateScreen());
        
      case AppRoutes.batchDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => BatchDetailScreen(batchId: args['batchId']),
        );
        
      case AppRoutes.batchHistory:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => BatchHistoryScreen(batchId: args['batchId']),
        );
        
      default:
        return _errorRoute();
    }
  }
  
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found')),
      ),
    );
  }
}