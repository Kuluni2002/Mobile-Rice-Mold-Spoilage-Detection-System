import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/app_constants.dart';

class GeminiService {
  GeminiService();

  Future<String> getRecommendation({
    required String dominantClass,
    required int healthyCount,
    required int earlyRiskCount,
    required int spoiledCount,
    required int total,
  }) async {
    if (AppConstants.geminiApiKey.isEmpty) {
      return _fallbackRecommendation(dominantClass);
    }

    final prompt = '''
You are an expert advisor for small-scale rice millers in Sri Lanka.
A rice grain batch has been analysed with the following results:

Total grains analysed : $total
Healthy grains        : $healthyCount 
                        (${(healthyCount/total*100).toStringAsFixed(1)}%)
Early risk grains     : $earlyRiskCount 
                        (${(earlyRiskCount/total*100).toStringAsFixed(1)}%)
Spoiled grains        : $spoiledCount 
                        (${(spoiledCount/total*100).toStringAsFixed(1)}%)
Dominant class        : $dominantClass

Provide a practical recommendation in 3-4 sentences for a 
Sri Lankan small-scale miller. Focus on:
- Immediate action to take
- Natural prevention methods (ventilation, moisture control, 
  neem leaves, ash — traditional Sri Lankan methods)
- When to re-scan
- Whether chemical treatment is needed

Keep language simple and practical. 
Do not use technical jargon.
''';

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: AppConstants.geminiApiKey,
      );
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? _fallbackRecommendation(dominantClass);
    } catch (e) {
      return _fallbackRecommendation(dominantClass);
    }
  }

  String _fallbackRecommendation(String dominantClass) {
    switch (dominantClass) {
      case 'healthy':
        return 'Your rice batch is in good condition. '
               'Maintain current storage with proper ventilation '
               'and moisture below 14%. Re-scan in 30 days.';
      case 'early_risk':
        return 'Early signs of mold detected. Immediately improve '
               'ventilation and check moisture levels. Apply neem '
               'leaves or ash as traditional preservatives. '
               'Re-scan in 7 days.';
      case 'spoiled':
        return 'Significant mold contamination detected. Isolate '
               'this batch immediately. Do not mix with healthy '
               'stock. Consult your supplier and consider '
               'industrial processing only.';
      default:
        return 'Please re-scan for accurate results.';
    }
  }
}