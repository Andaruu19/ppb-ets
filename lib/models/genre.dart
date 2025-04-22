import 'package:isar/isar.dart';
import 'book.dart'; // Import model Book untuk Backlink

part 'genre.g.dart'; // Shared generated part file

@collection
class Genre {
  Id id = Isar.autoIncrement;

  @Index(unique: true, caseSensitive: false)
  String? name;

  // Backlink ke field 'genres' di model 'Book'
  @Backlink(to: 'genres')
  final books = IsarLinks<Book>();

  Genre({this.name}); // Constructor opsional
}

