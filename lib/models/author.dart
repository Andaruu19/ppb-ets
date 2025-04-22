import 'package:isar/isar.dart';
import 'book.dart'; // Import model Book untuk Backlink

part 'author.g.dart'; // Shared generated part file

@collection
class Author {
  Id id = Isar.autoIncrement;

  @Index(unique: true, caseSensitive: false)
  String? name;
  String? hometown;

  // Backlink ke field 'genres' di model 'Book'
  @Backlink(to: 'authors')
  final books = IsarLinks<Book>();

  Author({this.name, this.hometown}); // Constructor opsional
}

