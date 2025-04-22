import 'package:isar/isar.dart';
import 'author.dart'; // Import model Genre untuk IsarLinks

part 'book.g.dart'; // Shared generated part file

@collection
class Book {
  Id id = Isar.autoIncrement;

  @Index()
  String? title;
  String? synopsis;
  int? publicationYear;

  // Link ke banyak objek Genre
  final authors = IsarLinks<Author>();
  

  Book({this.title, this.synopsis, this.publicationYear}); // Constructor opsional
}