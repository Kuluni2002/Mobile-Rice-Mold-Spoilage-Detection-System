import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/grain_models.dart';

class SAMService {
  Future<List<GrainBox>> segmentGrains(File imageFile) async {
    try {
      // Convert image to base64
      final bytes   = await imageFile.readAsBytes();
      final base64Img = base64Encode(bytes);

      // Send to SAM API
      final response = await http.post(
        Uri.parse('${AppConstants.samApiUrl}'
                  '${AppConstants.samSegmentEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Img}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data   = jsonDecode(response.body);
        final grains = (data['grains'] as List)
            .map((g) => GrainBox.fromJson(g))
            .toList();
        return grains;
      } else {
        throw Exception('SAM API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('SAM service failed: $e');
    }
  }
}