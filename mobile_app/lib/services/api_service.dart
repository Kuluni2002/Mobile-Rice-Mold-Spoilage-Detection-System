import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://your-backend.onrender.com';
  
  Future<List<Uint8List>> segmentRiceGrains(Uint8List imageBytes) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/segment'));
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes));
      
      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        
        List<Uint8List> grains = [];
        for (var grainData in json['grains']) {
          grains.add(base64Decode(grainData));
        }
        
        return grains;
      } else {
        throw Exception('Segmentation failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API error: $e');
      rethrow;
    }
  }

  Future<bool> checkHealth() async {
    try {
      var response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}