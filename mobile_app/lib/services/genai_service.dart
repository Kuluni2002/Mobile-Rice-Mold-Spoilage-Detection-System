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
    final normalizedLabel = _normaliseLabel(label);
    debugPrint('GenAI label=$normalizedLabel');
    if (!_isSupportedLabel(normalizedLabel)) {
      final fallback = _fallback(normalizedLabel);
      _logFromAi(false);
      _logSections(fallback);
      return Recommendation(text: fallback, fromAi: false);
    }
    final key = AppConstants.geminiApiKey;
    if (key.isEmpty) {
      final fallback = _fallback(normalizedLabel);
      _logFromAi(false);
      _logSections(fallback);
      return Recommendation(
        text: fallback,
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
                    {'text': _buildPrompt(normalizedLabel)},
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

      debugPrint('GenAI HTTP ${response.statusCode}');
      if (response.statusCode == 200) {
        final text = _extractText(response.body);
        if (text != null && text.isNotEmpty) {
          final cleaned = _clean(text);
          _logFromAi(true);
          _logSections(cleaned);
          return Recommendation(text: cleaned, fromAi: true);
        }
        debugPrint('Gemini: empty answer: ${_short(response.body)}');
        final fallback = _fallback(normalizedLabel);
        _logFromAi(false);
        _logSections(fallback);
        return Recommendation(
          text: fallback,
          fromAi: false,
          note: 'AI returned an empty answer. Showing built-in guidance.',
        );
      }

      debugPrint('Gemini HTTP ${response.statusCode}: ${_short(response.body)}');
      final fallback = _fallback(normalizedLabel);
      _logFromAi(false);
      _logSections(fallback);
      return Recommendation(
        text: fallback,
        fromAi: false,
        note: '${_statusMessage(response.statusCode)} Showing built-in guidance.',
      );
    } on TimeoutException {
      final fallback = _fallback(normalizedLabel);
      _logFromAi(false);
      _logSections(fallback);
      return Recommendation(
        text: _fallback(normalizedLabel),
        fromAi: false,
        note: 'AI took too long to answer. Showing built-in guidance.',
      );
    } on SocketException {
      final fallback = _fallback(normalizedLabel);
      _logFromAi(false);
      _logSections(fallback);
      return Recommendation(
        text: fallback,
        fromAi: false,
        note: 'No internet connection. Showing built-in guidance.',
      );
    } catch (e) {
      debugPrint('Gemini error: $e');
      final fallback = _fallback(normalizedLabel);
      _logFromAi(false);
      _logSections(fallback);
      return Recommendation(
        text: fallback,
        fromAi: false,
        note: 'AI is unavailable right now. Showing built-in guidance.',
      );
    }
  }

  // ── Prompt ────────────────────────────────────────────────────────────────
  static String _buildPrompt(String label) {
    const outputRules = '''
OUTPUT RULES (all three): plain text only, no markdown, no asterisks, no # headings; put each section title on its own line, followed by 2 or 3
bullets that start with "• "; simple words; do not mention the app, AI or any numbers.''';
    const opening = 'You are an advisor for small-scale rice farmers and millers in Sri Lanka. A phone app checked a sample of stored rice and gave this overall result:';

    switch (_normaliseLabel(label)) {
      case 'healthy':
        return '''$opening HEALTHY.
Meaning: most grains look healthy, no clear signs of mold.
Goal: keep it that way. Tone: calm and reassuring, short (under 150 words).
Section titles (exact): "Keep it healthy" / "Traditional methods" / "Storage checklist" / "Next check".
Must include: dry the rice well before storing (about 14% moisture or lower), good airflow, sacks on wooden planks off the floor and away from walls, look through the stock about once a month; traditional: dried neem (kohomba) leaves between sacks, clean sacks or clay pots, sun-drying on a clean mat if it feels damp. Next check: scan again in about 30 days.
Must NOT include: words like discard, danger or urgent.

$outputRules''';
      case 'early_risk':
        return '''$opening EARLY_RISK.
Meaning: many grains show the first signs of mold or damp damage; there is still time to act.
Goal: stop it spreading and save the stock. Tone: calm but urgent.
Section titles (exact): "Act within 48 hours" / "Check and separate" / "Traditional methods" / "Re-scan plan".
Must include: spread the rice out and sun-dry it on a clean mat, let it cool before storing; pick out discoloured or musty grains and keep them apart; improve airflow and move the stock away from damp walls and floors; traditional: dried neem (kohomba) leaves and a thin layer of clean wood ash help against pests but do NOT remove mold that has already started; do not eat grains that look moldy; re-scan in 3 to 7 days and treat the rice as spoiled if the smell or colour gets worse.

$outputRules''';
      case 'spoiled':
        return '''$opening SPOILED.
Meaning: many grains are visibly moldy or heavily discoloured; the rice is not safe.
Goal: safety first, stop the contamination spreading. Tone: serious and clear, no panic.
Section titles (exact): "Safety first" / "What to do with this stock" / "Protect the rest" / "Traditional methods".
Must include: separate the moldy grains right away; do not eat them or feed them to animals, because cooking and washing do not remove mold toxins; throw them away in a sealed bag, away from animals and from other stock; cover the nose and mouth and wash hands after handling; check other batches stored nearby; find and fix the cause (leaks, damp, poor airflow); for a large quantity ask the local agriculture officer or the supplier. Traditional methods: sun-dry and clean containers and sacks, and keep the remaining clean rice with dried neem (kohomba) leaves, but state clearly that neem, ash or sun-drying cannot cure rice that is already moldy. Re-scan the rest in 2 to 3 days.
Must NOT suggest that moldy rice can be saved by washing, drying or neem. No medical advice.

$outputRules''';
      default:
        return '';
    }
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
    switch (_normaliseLabel(label)) {
      case 'healthy':
        return '''Keep it healthy
• Dry the rice well before storing, to about 14% moisture or lower, and keep good airflow.
• Look through the stock about once a month.

Traditional methods
• Put dried neem (kohomba) leaves between sacks, and use clean sacks or clay pots.
• If it feels damp, sun-dry it on a clean mat before storing.

Storage checklist
• Keep sacks on wooden planks, off the floor and away from walls.
• Keep the storage area dry and well aired.

Next check
• Scan again in about 30 days.''';
      case 'early_risk':
        return '''Act within 48 hours
• Spread the rice out and sun-dry it on a clean mat, then let it cool before storing.
• Improve airflow and move the stock away from damp walls and floors.

Check and separate
• Pick out discoloured or musty grains and keep them apart.
• Do not eat grains that look moldy.

Traditional methods
• Dried neem (kohomba) leaves and a thin layer of clean wood ash help against pests.
• They do not remove mold that has already started.

Re-scan plan
• Re-scan in 3 to 7 days and treat the rice as spoiled if smell or colour gets worse.''';
      case 'spoiled':
        return '''Safety first
• Separate the moldy grains right away. Do not eat them or feed them to animals.
• Cover the nose and mouth and wash hands after handling.

What to do with this stock
• Throw the moldy grains away in a sealed bag, away from animals and other stock.
• Cooking and washing do not remove mold toxins.

Protect the rest
• Check other nearby batches and fix leaks, damp or poor airflow.
• For a large quantity, ask the local agriculture officer or the supplier.

Traditional methods
• Sun-dry and clean containers and sacks, and keep clean rice with dried neem (kohomba) leaves.
• Neem, ash or sun-drying cannot cure rice that is already moldy. Re-scan the rest in 2 to 3 days.''';
      default:
        return 'No guidance available. Please scan again.';
    }
  }

  static String _normaliseLabel(String label) {
    return label.trim().toLowerCase().replaceAll('-', '_');
  }

  static bool _isSupportedLabel(String label) {
    return label == 'healthy' || label == 'early_risk' || label == 'spoiled';
  }

  static void _logFromAi(bool fromAi) {
    debugPrint('GenAI fromAi=$fromAi');
  }

  static void _logSections(String text) {
    const sectionTitles = {
      'Keep it healthy',
      'Traditional methods',
      'Storage checklist',
      'Next check',
      'Act within 48 hours',
      'Check and separate',
      'Re-scan plan',
      'Safety first',
      'What to do with this stock',
      'Protect the rest',
    };
    for (final line in text.split('\n')) {
      final title = line.trim();
      if (sectionTitles.contains(title)) {
        debugPrint('GenAI section=$title');
      }
    }
  }
}
