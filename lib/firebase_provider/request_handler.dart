import 'package:http/http.dart' as http;
import 'dart:convert';

import 'firestore_values_util.dart';

enum Method { GET, POST, PATCH, DELETE }

class Response {
  final bool error;
  final int statusCode;
  final String? message;
  final dynamic data;

  Response({
    required this.error,
    required this.statusCode,
    this.message,
    required this.data,
  });

  factory Response.fromHttpResponse(http.Response response) {
    try {
      final bodyJson = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Response(
          error: false,
          statusCode: response.statusCode,
          data: getFirestoreValues(bodyJson),
        );
      } else {
        String errorMessage;
        switch (response.statusCode) {
          case 404:
            errorMessage = 'No se encontraron los datos';
            break;
          case -1:
            errorMessage = 'Sin acceso a internet';
            break;
          default:
            errorMessage = 'Error del servidor';
        }

        return Response(
          error: true,
          statusCode: response.statusCode,
          message: errorMessage,
          data: bodyJson,
        );
      }
    } catch (e) {
      return Response(
        error: true,
        statusCode: response.statusCode,
        message: 'Sin acceso a internet',
        data: response.body,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'error': error,
      'statusCode': statusCode,
      'message': message,
      'data': data,
    };
  }
}

Map<String, dynamic> handleResponse(http.Response response) {
  return Response.fromHttpResponse(response).toMap();
}

Future<Map<String, dynamic>> sendRequest(
  Method method,
  String url, {
  Map<String, dynamic>? data,
  Map<String, String>? headers,
}) async {
  final uri = Uri.parse(url);
  final requestHeaders = {"Content-Type": "application/json", ...?headers};

  // Conditionally apply toFirestoreValues
  // Do not apply for runQuery endpoint, as it expects structuredQuery directly
  final bool isRunQuery = url.endsWith(':runQuery');
  final body = data != null
      ? (isRunQuery ? json.encode(data) : json.encode(toFirestoreValues(data)))
      : null;

  try {
    http.Response response;
    switch (method) {
      case Method.GET:
        response = await http.get(uri, headers: requestHeaders);
        break;
      case Method.POST:
        response = await http.post(uri, headers: requestHeaders, body: body);
        break;
      case Method.PATCH:
        response = await http.patch(uri, headers: requestHeaders, body: body);
        break;
      case Method.DELETE:
        response = await http.delete(uri, headers: requestHeaders);
        break;
    }
    return handleResponse(response);
  } catch (e) {
    // Handle network exceptions gracefully
    return Response(
      error: true,
      statusCode: -1,
      message: 'Sin acceso a internet',
      data: null,
    ).toMap();
  }
}
