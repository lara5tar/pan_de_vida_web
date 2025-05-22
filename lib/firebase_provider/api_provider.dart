import 'dart:convert';

import 'request_handler.dart';

class FirebaseApiProvider {
  final String idProject;
  final String model;
  late String urlBase;

  FirebaseApiProvider({required this.idProject, required this.model}) {
    urlBase =
        'https://firestore.googleapis.com/v1/projects/$idProject/databases/(default)/documents/$model';
  }

  Future<Map<String, dynamic>> getAll({Map<String, String>? headers}) async {
    return await sendRequest(Method.GET, urlBase, headers: headers);
  }

  Future<Map<String, dynamic>> get(
    String id, {
    Map<String, String>? headers,
  }) async {
    Map<String, dynamic> data = await sendRequest(
      Method.GET,
      '$urlBase/$id',
      headers: headers,
    );
    print('get response: $data');
    return data;
  }

  // Método original que crea un documento con ID automático generado por Firebase
  Future<Map<String, dynamic>> add(
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    return await sendRequest(
      Method.POST,
      urlBase,
      data: data,
      headers: headers,
    );
  }

  // Método modificado para crear un documento con ID personalizado
  Future<Map<String, dynamic>> addWithCustomId(
    String customId,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    // Para la API de Firestore, usamos ?documentId={customId} para especificar un ID personalizado
    final String urlWithCustomId = '$urlBase?documentId=$customId';
    return await sendRequest(
      Method.POST,
      urlWithCustomId,
      data: data,
      headers: headers,
    );
  }

  // Este método ahora sirve para trabajar con documentos anidados (subdocumentos)
  Future<Map<String, dynamic>> addDocument(
    String parentDocumentId,
    String subCollection,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    String? customDocumentId,
  }) async {
    String url = '$urlBase/$parentDocumentId/$subCollection';

    // Si se proporciona un ID personalizado para el subdocumento, lo añadimos a la URL
    if (customDocumentId != null) {
      url = '$url?documentId=$customDocumentId';
    }

    return await sendRequest(Method.POST, url, data: data, headers: headers);
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    return await sendRequest(
      Method.PATCH,
      '$urlBase/$id',
      data: data,
      headers: headers,
    );
  }

  // Método para consultar documentos por un campo específico
  Future<List<Map<String, dynamic>>> queryByField({
    required String field,
    required String value,
    Map<String, String>? headers,
  }) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/$idProject/databases/(default)/documents:runQuery';

    // Ensure the 'value' in queryBody is correctly typed for Firestore.
    // For this example, assuming stringValue. Adjust if field type is different (e.g., integerValue).
    final queryBody = {
      "structuredQuery": {
        "from": [
          {"collectionId": model},
        ],
        "where": {
          "fieldFilter": {
            "field": {"fieldPath": field},
            "op": "EQUAL",
            "value": {"stringValue": value},
          },
        },
      },
    };

    final dynamic responseMap = await sendRequest(
      Method.POST,
      url,
      data: queryBody,
      headers: headers,
    );

    print('queryByField responseMap: $responseMap');

    if (responseMap is! Map) {
      print('Unexpected response type from sendRequest: $responseMap');
      return [];
    }

    bool hasError =
        responseMap.containsKey('error') && responseMap['error'] == true;
    int statusCode =
        responseMap.containsKey('statusCode')
            ? responseMap['statusCode'] as int
            : -1;
    String message =
        responseMap.containsKey('message')
            ? responseMap['message'] as String? ?? ''
            : '';
    dynamic responseData =
        responseMap.containsKey('data') ? responseMap['data'] : null;

    // Primary condition for success: statusCode 2xx
    if (statusCode >= 200 && statusCode < 300) {
      if (hasError) {
        print(
          'Warning: Error flag is true but statusCode is $statusCode. Message: $message. Attempting to process data.',
        );
      }

      dynamic dataToProcess = responseData;
      if (responseData is String) {
        try {
          dataToProcess = json.decode(responseData);
        } catch (e) {
          print(
            'Failed to decode string data from response (statusCode $statusCode): $e',
          );
          return []; // Cannot process if string data is malformed
        }
      }

      if (dataToProcess is List) {
        return dataToProcess
            .where(
              (item) =>
                  item is Map &&
                  item.containsKey("document") &&
                  item["document"] != null,
            )
            .map<Map<String, dynamic>>(
              (item) => item["document"] as Map<String, dynamic>,
            )
            .toList();
      } else {
        print(
          'Successful response (status $statusCode), but data is not a list or is null after processing: $dataToProcess',
        );
        return [];
      }
    } else {
      // Handle actual errors (non-2xx status codes)
      print(
        'Request failed or error explicitly flagged: StatusCode: $statusCode, Message: $message',
      );
      return [];
    }
  }

  // Método para consultar documentos y formatear los datos para facilitar su uso
  Future<List<Map<String, dynamic>>> queryByFieldFormatted({
    required String field,
    required String value,
    Map<String, String>? headers,
  }) async {
    // Obtener los documentos sin procesar
    final documents = await queryByField(
      field: field,
      value: value,
      headers: headers,
    );

    // Procesar cada documento para extraer y formatear sus campos
    return documents
        .map<Map<String, dynamic>>((doc) => processFirestoreDocument(doc))
        .toList();
  }

  // Método auxiliar para procesar un documento de Firestore y extraer sus campos de manera estructurada
  Map<String, dynamic> processFirestoreDocument(Map<String, dynamic> document) {
    // Resultado procesado
    Map<String, dynamic> result = {};

    // Obtener la ruta completa del documento y extraer el ID
    final String docPath = document['name'] ?? '';
    final String id = docPath.isNotEmpty ? docPath.split('/').last : '';

    // Añadir el ID al resultado
    result['id'] = id;

    // Procesar los campos del documento
    final Map<String, dynamic> firestoreFields = document['fields'] ?? {};
    firestoreFields.forEach((key, value) {
      // Extraer el valor según su tipo en Firestore
      if (value is Map) {
        if (value.containsKey('stringValue')) {
          result[key] = value['stringValue'];
        } else if (value.containsKey('integerValue')) {
          result[key] = int.parse(value['integerValue'].toString());
        } else if (value.containsKey('doubleValue')) {
          result[key] = double.parse(value['doubleValue'].toString());
        } else if (value.containsKey('booleanValue')) {
          result[key] = value['booleanValue'];
        } else if (value.containsKey('nullValue')) {
          result[key] = null;
        } else if (value.containsKey('arrayValue')) {
          // Manejar arrays
          final arrayValue = value['arrayValue'];
          if (arrayValue != null && arrayValue['values'] != null) {
            result[key] =
                (arrayValue['values'] as List)
                    .map((item) => processFirestoreValue(item))
                    .toList();
          } else {
            result[key] = [];
          }
        } else if (value.containsKey('mapValue')) {
          // Manejar objetos anidados
          final mapValue = value['mapValue'];
          if (mapValue != null && mapValue['fields'] != null) {
            Map<String, dynamic> nestedResult = {};
            mapValue['fields'].forEach((nestedKey, nestedValue) {
              nestedResult[nestedKey] = processFirestoreValue(nestedValue);
            });
            result[key] = nestedResult;
          } else {
            result[key] = {};
          }
        } else {
          // Para otros tipos o casos no manejados
          result[key] = value.toString();
        }
      }
    });

    return result;
  }

  // Método auxiliar para procesar un valor individual de Firestore
  dynamic processFirestoreValue(Map<String, dynamic> value) {
    if (value.containsKey('stringValue')) {
      return value['stringValue'];
    } else if (value.containsKey('integerValue')) {
      return int.parse(value['integerValue'].toString());
    } else if (value.containsKey('doubleValue')) {
      return double.parse(value['doubleValue'].toString());
    } else if (value.containsKey('booleanValue')) {
      return value['booleanValue'];
    } else if (value.containsKey('nullValue')) {
      return null;
    } else {
      return value.toString();
    }
  }

  Future<Map<String, dynamic>> delete(
    String id, {
    Map<String, String>? headers,
  }) async {
    return await sendRequest(Method.DELETE, '$urlBase/$id', headers: headers);
  }

  // Método para actualizar campos específicos sin sobrescribir el documento completo
  Future<Map<String, dynamic>> updateFields(
    String id,
    Map<String, dynamic> fields, {
    Map<String, String>? headers,
  }) async {
    try {
      // Primero obtenemos el documento actual para no perder datos
      Map<String, dynamic> currentDocument = await get(id, headers: headers);

      // Ahora actualizamos solo los campos específicos
      Map<String, dynamic> updatedData = {};

      // Si el documento tiene estructura de Firestore con fields, la manejamos
      if (currentDocument.containsKey('fields')) {
        // Creamos un nuevo objeto con los campos actuales
        updatedData = {...currentDocument};

        // Actualizamos sólo los campos específicos
        fields.forEach((key, value) {
          if (!updatedData['fields'].containsKey(key)) {
            updatedData['fields'][key] = {};
          }

          // Dependiendo del tipo del valor, lo formateamos según el formato de Firestore
          if (value is String) {
            updatedData['fields'][key] = {'stringValue': value};
          } else if (value is int) {
            updatedData['fields'][key] = {'integerValue': value};
          } else if (value is double) {
            updatedData['fields'][key] = {'doubleValue': value};
          } else if (value is bool) {
            updatedData['fields'][key] = {'booleanValue': value};
          } else if (value is List) {
            updatedData['fields'][key] = {
              'arrayValue': {
                'values':
                    value.map((item) => convertToFirestoreValue(item)).toList(),
              },
            };
          } else if (value == null) {
            updatedData['fields'][key] = {'nullValue': null};
          } else if (value is Map) {
            updatedData['fields'][key] = {
              'mapValue': {'fields': convertMapToFirestoreFields(value)},
            };
          }
        });

        // Usamos una operación PATCH para actualizar el documento
        return await sendRequest(
          Method.PATCH,
          '$urlBase/$id',
          data: updatedData,
          headers: headers,
        );
      } else {
        // Si es una respuesta procesada, intentamos un enfoque directo
        fields.forEach((key, value) {
          updatedData[key] = value;
        });

        return await update(id, updatedData, headers: headers);
      }
    } catch (e) {
      return {'error': true, 'message': 'Error al actualizar campos: $e'};
    }
  }

  // Método auxiliar para convertir un valor a formato Firestore
  dynamic convertToFirestoreValue(dynamic value) {
    if (value is String) {
      return {'stringValue': value};
    } else if (value is int) {
      return {'integerValue': value};
    } else if (value is double) {
      return {'doubleValue': value};
    } else if (value is bool) {
      return {'booleanValue': value};
    } else if (value is List) {
      return {
        'arrayValue': {
          'values': value.map((item) => convertToFirestoreValue(item)).toList(),
        },
      };
    } else if (value == null) {
      return {'nullValue': null};
    } else if (value is Map) {
      // Acepta mapas con cualquier tipo de clave y los convierte a String
      return {
        'mapValue': {'fields': convertMapToFirestoreFields(value)},
      };
    } else {
      return {'stringValue': value.toString()};
    }
  }

  // Método auxiliar para convertir un mapa a formato de campos Firestore
  Map<String, dynamic> convertMapToFirestoreFields(Map map) {
    Map<String, dynamic> result = {};
    map.forEach((key, value) {
      // Asegurarnos de que la clave sea un String
      String stringKey = key.toString();
      result[stringKey] = convertToFirestoreValue(value);
    });
    return result;
  }
}
