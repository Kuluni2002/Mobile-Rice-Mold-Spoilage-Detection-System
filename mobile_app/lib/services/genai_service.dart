import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/classification_result.dart';
import '../core/constants/app_constants.dart';

class GenAIService {
  
  /// Generate personalized recommendations using Gemini AI
  static Future<String> generateRecommendations(
    ClassificationResult result, {
    String? additionalContext,
  }) async {
    if (AppConstants.geminiApiKey.isEmpty) {
      return _getFallbackRecommendations(result);
    }

    final apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${AppConstants.geminiApiKey}';

    try {
      // Build the prompt based on classification
      final prompt = _buildPrompt(result, additionalContext);
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recommendations = data['content'][0]['text'] as String;
        return recommendations;
      } else {
        return _getFallbackRecommendations(result);
      }
    } catch (e) {
      return _getFallbackRecommendations(result);
    }
  }
  
  /// Build the prompt for Gemini based on classification result
  static String _buildPrompt(
    ClassificationResult result,
    String? additionalContext,
  ) {
    final label = result.label.toLowerCase();
    final confidence = (result.confidence * 100).toStringAsFixed(1);
    
    String prompt = '''You are a rice storage and food safety expert. A rice mold detection AI has analyzed a batch of rice with the following results:

Classification: ${result.label.toUpperCase().replaceAll('_', ' ')}
Confidence: $confidence%
Risk Level: ${result.riskLevel}
Scan Time: ${result.timestamp.toString()}

''';

    if (additionalContext != null && additionalContext.isNotEmpty) {
      prompt += 'Additional Context: $additionalContext\n\n';
    }

    switch (label) {
      case 'healthy':
      case AppConstants.classHealthy:
        prompt += '''The rice appears healthy with no visible mold contamination.

Please provide:
1. Best practices to maintain this healthy state
2. Optimal storage conditions (temperature, humidity, ventilation)
3. Recommended monitoring schedule
4. Preventive measures to avoid future contamination
5. Expected shelf life under proper conditions

Format your response as a clear, actionable list that a rice farmer or storage facility manager can follow.''';
        break;
        
      case 'early_risk':
      case AppConstants.classEarlyRisk:
        prompt += '''The rice shows early signs of potential mold development. This is a critical stage where intervention can prevent major losses.

Please provide:
1. Immediate actions to take within the next 24-48 hours
2. Signs to monitor closely
3. Environmental factors to adjust (humidity, temperature, airflow)
4. Methods to separate and inspect suspicious grains
5. Timeline for re-scanning
6. When to consider discarding portions

Format your response with urgency indicators and prioritized steps.''';
        break;
        
      case 'spoiled':
      case AppConstants.classSpoiled:
        prompt += '''The rice is heavily contaminated with mold and is not safe for consumption.

Please provide:
1. CRITICAL safety warnings about consumption risks
2. Immediate disposal procedures
3. Steps to prevent contamination spread to other batches
4. Storage facility cleaning and disinfection protocol
5. Root cause analysis - what likely went wrong
6. Preventive measures to avoid recurrence
7. Financial mitigation options (insurance, salvage)

Format your response with clear safety warnings and step-by-step remediation actions.''';
        break;
        
      default:
        prompt += 'Please provide general rice storage recommendations.';
    }
    
    prompt += '\n\nKeep recommendations practical, specific, and actionable. Use bullet points for clarity.';
    
    return prompt;
  }
  
  /// Fallback recommendations if API call fails
  static String _getFallbackRecommendations(ClassificationResult result) {
    switch (result.label.toLowerCase()) {
      case 'healthy':
      case AppConstants.classHealthy:
        return '''• Maintain proper ventilation in storage area
- Keep moisture content below 14%
- Store in cool, dry conditions (15-20°C)
- Use airtight containers when possible
- Schedule next scan in 30 days
- Continue current storage practices
- Monitor for any changes in appearance or odor''';
        
      case 'early_risk':
      case AppConstants.classEarlyRisk:
        return '''• Inspect affected grains immediately
- Improve storage ventilation right away
- Reduce moisture levels urgently
- Separate suspicious grains from healthy ones
- Check storage temperature and humidity
- Re-scan within 7 days
- Consider moving to drier storage location
- Monitor daily for any progression''';
        
      case 'spoiled':
      case AppConstants.classSpoiled:
        return '''⚠️ CRITICAL - DO NOT CONSUME THIS RICE

- Discard heavily molded grains immediately
- Do not attempt to salvage moldy rice
- Use protective equipment when handling
- Deep clean and disinfect storage area
- Check for moisture leaks or pest issues
- Review and fix storage conditions
- Inspect nearby batches for contamination
- Document for insurance/records''';
        
      default:
        return '• No specific recommendations available. Please consult a food safety expert.';
    }
  }
}