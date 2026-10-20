import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
const OnboardingScreen({super.key});
@override
State<OnboardingScreen> createState() => _OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
final PageController _pageController = PageController();
int _currentPage = 0;
final List<OnboardingPage> _pages = [
OnboardingPage(
title: 'Detect Mold Early',
description: 'AI-powered system identifies rice mold at early stages '
'when natural prevention methods are still effective',
icon: Icons.search,
color: AppColors.healthy,
),
OnboardingPage(
title: 'Quick Batch Assessment',
description: 'Scan 50-100 grains at once with your smartphone camera. '
'Results in seconds, not minutes',
icon: Icons.camera_alt,
color: AppColors.primary,
),
OnboardingPage(
title: 'Track Quality Over Time',
description: 'Monitor batch quality progression and get alerts when '
'intervention is needed',
icon: Icons.trending_up,
color: AppColors.earlyRisk,
),
OnboardingPage(
title: 'Get Actionable Guidance',
description: 'Receive stage-specific recommendations using natural '
'preservation methods',
icon: Icons.lightbulb_outline,
color: AppColors.primaryLight,
),
];
@override
void dispose() {
_pageController.dispose();
super.dispose();
}
Future<void> _completeOnboarding() async {
final prefs = await SharedPreferences.getInstance();
await prefs.setBool(AppConstants.keyIsFirstTime, false);
if (!mounted) return;
Navigator.of(context).pushReplacementNamed(AppRoutes.pinSetup);
}
@override
Widget build(BuildContext context) {
return Scaffold(
body: SafeArea(
child: Column(
children: [
// Skip button
Align(
alignment: Alignment.topRight,
child: TextButton(
onPressed: _completeOnboarding,
child: const Text('Skip'),
),
),
        // Page content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
        ),
        
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _pages.length,
            (index) => _buildIndicator(index == _currentPage),
          ),
        ),
        const SizedBox(height: 32),
        
        // Navigation button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage == _pages.length - 1) {
                  _completeOnboarding();
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Text(
                _currentPage == _pages.length - 1
                    ? 'Get Started'
                    : 'Next',
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ),
  ),
);
}
Widget _buildPage(OnboardingPage page) {
return Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Container(
width: 200,
height: 200,
decoration: BoxDecoration(
color: page.color.withOpacity(0.1),
shape: BoxShape.circle,
),
child: Icon(
page.icon,
size: 100,
color: page.color,
),
),
const SizedBox(height: 48),
      Text(
        page.title,
        style: Theme.of(context).textTheme.displayMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      
      Text(
        page.description,
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
    ],
  ),
);
}
Widget _buildIndicator(bool isActive) {
return AnimatedContainer(
duration: const Duration(milliseconds: 300),
margin: const EdgeInsets.symmetric(horizontal: 4),
width: isActive ? 24 : 8,
height: 8,
decoration: BoxDecoration(
color: isActive ? AppColors.primary : AppColors.divider,
borderRadius: BorderRadius.circular(4),
),
);
}
}
class OnboardingPage {
final String title;
final String description;
final IconData icon;
final Color color;
OnboardingPage({
required this.title,
required this.description,
required this.icon,
required this.color,
});
}
