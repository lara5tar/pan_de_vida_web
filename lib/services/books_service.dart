import '../firebase_provider/api_provider.dart';
import '../models/book_model.dart';

class BooksService {
  static final FirebaseApiProvider fireProvider = FirebaseApiProvider(
    idProject: 'pandevida-td',
    model: 'books',
  );

  Future<Map> getAll() async {
    List<Book> books = [];
    Map<String, dynamic> data = await fireProvider.getAll();

    if (data['error']) {
      return data;
    } else {
      print('BooksService.getAll');
      data['data'].forEach((key, value) {
        // Se asigna la key como id para tener la referencia en Firebase
        var bookData = value;
        bookData['id'] = key;
        books.add(Book.fromJson(bookData));
      });
      return {'error': false, 'data': books};
    }
  }

  Future<Book> getById(String id) async {
    Map<String, dynamic> data = await fireProvider.get(id);
    data['id'] = id; // Aseguramos que el ID esté presente
    return Book.fromJson(data);
  }

  // Método modificado para usar IDs automáticos en la creación
  Future<Map<String, dynamic>> add(Book book) async {
    try {
      // Se usa add() para generar ID automático en lugar de addWithCustomId
      var bookData = book.toJson();
      // Eliminamos el ID del objeto si está vacío para que Firebase genere uno automático
      if (book.id.isEmpty) {
        bookData.remove('id');
      }
      return await fireProvider.add(bookData);
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> update(Book book) async {
    try {
      return await fireProvider.update(book.id, book.toJson());
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  // Método para buscar un libro por su código de barras
  Future<Map<String, dynamic>> findByBarcode(String barcode) async {
    try {
      // Utilizamos el nuevo método queryByFieldFormatted del FirebaseApiProvider
      // que ya devuelve los datos estructurados correctamente
      final results = await fireProvider.queryByFieldFormatted(
        field: 'codigoBarras',
        value: barcode,
      );

      // Si no hay resultados, retornamos error sin mostrar diálogo
      if (results.isEmpty) {
        return {
          'error': true,
          'message':
              'No se encontró ningún libro con el código de barras: $barcode',
        };
      }

      // Si encontramos resultados, usamos el primero para crear un objeto Book
      // Los datos ya vienen formateados correctamente por el ApiProvider
      final bookData = results[0];
      final Book book = Book.fromJson(bookData);

      return {'error': false, 'data': book};
    } catch (e) {
      return {
        'error': true,
        'message':
            'Error al buscar libro por código de barras: ${e.toString()}',
      };
    }
  }

  // Nuevo método para buscar libros por similitud en el nombre
  Future<Map<String, dynamic>> findByNameSimilarity(String searchTerm) async {
    try {
      // Primero obtenemos todos los libros
      final allBooksResult = await getAll();

      // Si hay un error al obtener los libros, lo retornamos
      if (allBooksResult['error'] == true) {
        return allBooksResult as Map<String, dynamic>;
      }

      // Obtenemos la lista de libros
      final List<Book> allBooks = allBooksResult['data'];

      // Si la lista está vacía, retornamos que no se encontraron libros
      if (allBooks.isEmpty) {
        return {
          'error': true,
          'message': 'No hay libros disponibles para buscar',
        };
      }

      // Convertimos el término de búsqueda a minúsculas para comparación insensible a mayúsculas/minúsculas
      final lowercaseSearchTerm = searchTerm.toLowerCase();

      // Filtramos los libros que contienen el término de búsqueda en su nombre
      final List<Book> matchedBooks =
          allBooks.where((book) {
            return book.nombre.toLowerCase().contains(lowercaseSearchTerm);
          }).toList();

      // Si no hay libros que coincidan, retornamos error
      if (matchedBooks.isEmpty) {
        return {
          'error': true,
          'message': 'No se encontraron libros que coincidan con: $searchTerm',
        };
      }

      // Devolvemos los libros que coinciden
      return {'error': false, 'data': matchedBooks};
    } catch (e) {
      return {
        'error': true,
        'message': 'Error al buscar libros por nombre: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> delete(String id) async {
    return await fireProvider.delete(id);
  }
}
