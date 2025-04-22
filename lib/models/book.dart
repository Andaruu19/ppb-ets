import 'package:isar/isar.dart';
import 'genre.dart'; // Import model Genre untuk IsarLinks

part 'book.g.dart'; // Shared generated part file

@collection
class Book {
  Id id = Isar.autoIncrement;

  @Index()
  String? title;

  String? author;
  String? synopsis;
  int? publicationYear;

  // Link ke banyak objek Genre
  final genres = IsarLinks<Genre>();

  Book({this.title, this.author, this.synopsis, this.publicationYear}); // Constructor opsional
}