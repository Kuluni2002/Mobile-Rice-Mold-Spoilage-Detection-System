/*import 'dart:convert';
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
}*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

/// Advice shown on the Results screen.
class Recommendation {
  final String text;
  final bool fromAi; // false = built-in offline guidance
  final String? note; // why the offline guidance was used

  const Recommendation({
    required this.text,
    required this.fromAi,
    this.note,
  });
}

/// Generates storage advice with Gemini (raw REST, no SDK).
/// Gemini never takes part in the classification: it only receives the final
/// result (healthy / early risk / spoiled) and writes advice for that result.
class GenAIService {
  // Change this one line if Google retires or renames the model.
  static const String _model = 'gemini-3.8-flash';
  static const String _thinkingLevel = 'low'; // low / medium / high
  static const Duration _timeout = Duration(seconds: 30);

  static Future<Recommendation> getRecommendation({
    required String label, // healthy / early_risk / spoiled
  }) async {
    final key = AppConstants.geminiApiKey;
    if (key.isEmpty) {
      return Recommendation(
        text: _fallback(label),
        fromAi: false,
        note: 'AI is not set up on this device (no API key). Showing built-in guidance.',
      );
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent',
    );

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': key, // header, so the key never appears in a URL or log
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': _buildPrompt(label)},
                  ],
                },
              ],
              'generationConfig': {
                'maxOutputTokens': 1500,
                'thinkingConfig': {'thinkingLevel': _thinkingLevel},
              },
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final text = _extractText(response.body);
        if (text != null && text.isNotEmpty) {
          return Recommendation(text: _clean(text), fromAi: true);
        }
        debugPrint('Gemini: empty answer: ${_short(response.body)}');
        return Recommendation(
          text: _fallback(label),
          fromAi: false,
          note: 'AI returned an empty answer. Showing built-in guidance.',
        );
      }

      debugPrint('Gemini HTTP ${response.statusCode}: ${_short(response.body)}');
      return Recommendation(
        text: _fallback(label),
        fromAi: false,
        note: '${_statusMessage(response.statusCode)} Showing built-in guidance.',
      );
    } on TimeoutException {
      return Recommendation(
        text: _fallback(label),
        fromAi: false,
        note: 'AI took too long to answer. Showing built-in guidance.',
      );
    } on SocketException {
      return Recommendation(
        text: _fallback(label),
        fromAi: false,
        note: 'No internet connection. Showing built-in guidance.',
      );
    } catch (e) {
      debugPrint('Gemini error: $e');
      return Recommendation(
        text: _fallback(label),
        fromAi: false,
        note: 'AI is unavailable right now. Showing built-in guidance.',
      );
    }
  }

  // ── Prompt ────────────────────────────────────────────────────────────────
  static String _buildPrompt(String label) {
    final String meaning;
    switch (label.toLowerCase()) {
      case 'healthy':
        meaning = 'Most grains look healthy, with no clear signs of mold.';
        break;
      case 'early_risk':
        meaning = 'Many grains show the first signs of mold or damp damage. There is still time to act.';
        break;
      case 'spoiled':
        meaning = 'Many grains are visibly moldy or heavily discoloured.';
        break;
      default:
        meaning = 'The condition of the rice is unclear.';
    }

    return '''
You are an advisor for small-scale rice farmers and millers in Sri Lanka.
A phone app checked a sample of stored rice and gave one overall result.

Result: ${label.replaceAll('_', ' ')}
Meaning: $meaning

Write practical advice for this result in plain English with simple words.
Rules:
- Plain text only. No markdown, no asterisks, no # headings.
- Use exactly these four sections. Put each section title on its own line, then 2 or 3 bullets that start with "• ":
  What to do now
  Traditional methods
  Storage tips
  When to re-scan
- Under "Traditional methods" use ideas familiar in Sri Lanka, for example dried neem (kohomba) leaves between sacks, a thin layer of clean wood ash, sun-drying on a clean mat, clay pots or sealed containers, raised wooden planks. Say clearly that these help against pests and damp but cannot remove mold that has already formed.
- If the result is spoiled: say to separate and throw away the visibly moldy grains and not to eat them or feed them to animals, because cooking does not remove mold toxins. Do not give medical advice.
- If the result is healthy, keep it short and focus on prevention.
- Keep the whole answer under 200 words. Do not mention the app or AI.
''';
  }

  // ── Response handling ─────────────────────────────────────────────────────
  static String? _extractText(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;
      final content = (candidates.first as Map)['content'] as Map?;
      final parts = content?['parts'] as List?;
      if (parts == null) return null;
      final buffer = StringBuffer();
      for (final p in parts) {
        if (p is Map && p['thought'] != true && p['text'] is String) {
          buffer.write(p['text']);
        }
      }
      return buffer.toString().trim();
    } catch (_) {
      return null;
    }
  }

  // The screen shows plain text, so remove any markdown that slips through.
  static String _clean(String text) {
    var t = text.replaceAll('**', '').replaceAll('__', '');
    t = t.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
    t = t.replaceAll(RegExp(r'^\s*[\*\-]\s+', multiLine: true), '• ');
    return t.trim();
  }

  static String _short(String s) => s.length > 400 ? '${s.substring(0, 400)}...' : s;

  static String _statusMessage(int code) {
    if (code == 400) return 'AI request was rejected (check the API key).';
    if (code == 401 || code == 403) return 'The API key is not allowed to use this AI model.';
    if (code == 404) return 'The AI model is not available.';
    if (code == 429) return 'AI quota reached for now.';
    if (code >= 500) return 'The AI service is busy.';
    return 'AI is unavailable (error $code).';
  }

  // ── Built-in guidance, used when the AI cannot be reached ────────────────
  static String _fallback(String label) {
    switch (label.toLowerCase()) {
      case 'healthy':
        return '''What to do now
• Your rice looks healthy. Keep it dry and cool.

Traditional methods
• Put dried neem (kohomba) leaves between the sacks or on top of the grain to keep insects away.
• If the rice feels damp, dry it on a clean mat in the sun before storing.

Storage tips
• Keep sacks on wooden planks, off the floor and away from walls.
• Use sealed containers or clay pots for small amounts.

When to re-scan
• Scan again in about 30 days.''';
      case 'early_risk':
        return '''What to do now
• Spread the rice out and check for a musty smell, damp patches or discoloured grains.
• Pick out the discoloured grains and keep them apart from the healthy rice.

Traditional methods
• Sun-dry the rice on a clean mat for a few hours on a dry day, and let it cool before storing.
• Put dried neem (kohomba) leaves between the sacks. Neem helps against pests, but it cannot remove mold that has already started.

Storage tips
• Store on raised wooden planks with good airflow, away from damp walls and floors.

When to re-scan
• Scan again within 7 days and check the rice daily for smell or colour changes.''';
      case 'spoiled':
        return '''What to do now
• Separate the moldy grains right away. Do not eat them or feed them to animals: cooking does not remove mold toxins.
• Check the rest of the stock grain by grain.

Traditional methods
• Sun-dry the remaining clean rice on a mat and let it cool fully before storing.
• Use dried neem (kohomba) leaves and clean sacks for the good rice. They keep pests away but cannot cure mold.

Storage tips
• Clean and dry the storage area and fix any leaks or damp spots before storing rice again.

When to re-scan
• Scan the remaining rice again within 3 days.''';
      default:
        return 'No guidance available. Please scan again.';
    }
  }
}
