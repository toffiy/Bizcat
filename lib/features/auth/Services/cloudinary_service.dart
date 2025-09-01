import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


Future<String> uploadImageToCloudinary(XFile imageFile) async {
    final cloudName = 'ddpj3pix5';
    final uploadPreset = 'bizcat_unsigned';
    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode == 200 && data['secure_url'] != null) {
      return data['secure_url'];
    } else {
      throw Exception(
        "Cloudinary upload failed: ${data['error']?['message'] ?? 'Unknown error'}",
      );
    }
  }