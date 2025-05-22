import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  static const String uploadUrl =
      'https://sistemasdevida.com/app_pan/upload_image.php';

  // Método para seleccionar una imagen desde la galería o cámara
  static Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return pickedFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error al seleccionar imagen: $e');
      }
      return null;
    }
  }

  // Método para subir la imagen al servidor
  static Future<Map<String, dynamic>> uploadImage(XFile imageFile) async {
    try {
      // Crear la solicitud multipart
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Preparar el archivo para enviar
      final bytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
      );

      // Agregar el archivo a la solicitud
      request.files.add(multipartFile);

      // Enviar la solicitud
      final response = await request.send();

      // Obtener la respuesta como string
      final responseData = await response.stream.bytesToString();

      // Verificar si la solicitud fue exitosa
      if (response.statusCode == 200) {
        final Map<String, dynamic> parsedResponse = jsonDecode(responseData);

        // Si la respuesta tiene una URL, la carga fue exitosa
        if (parsedResponse.containsKey('url')) {
          return {'success': true, 'url': parsedResponse['url']};
        } else {
          // Si hay un error en la respuesta
          return {
            'success': false,
            'message': parsedResponse['error'] ?? 'Error desconocido',
          };
        }
      } else {
        // Si el código de estado no es 200
        return {
          'success': false,
          'message': 'Error en el servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      // En caso de error en la solicitud
      return {
        'success': false,
        'message': 'Error al subir la imagen: ${e.toString()}',
      };
    }
  }

  // Método para seleccionar y subir una imagen en un solo paso
  static Future<Map<String, dynamic>> pickAndUploadImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    // Seleccionar imagen
    final XFile? pickedFile = await pickImage(source: source);

    if (pickedFile == null) {
      return {'success': false, 'message': 'No se seleccionó ninguna imagen'};
    }

    // Subir la imagen seleccionada
    return await uploadImage(pickedFile);
  }
}
