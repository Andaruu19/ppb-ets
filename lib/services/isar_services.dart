import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/author.dart';
import '../models/book.dart';
import 'dart:async'; // Untuk Completer

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = _openDB(); // Inisialisasi saat service dibuat
  }

  // Membuka database Isar
  Future<Isar> _openDB() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.instanceNames.isEmpty) {
      // Hanya buka jika belum ada instance
      return await Isar.open(
        [BookSchema, AuthorSchema], // Sertakan SEMUA skema di sini
        directory: dir.path,
        inspector: true, // Aktifkan inspector untuk debugging (opsional)
        name: 'libraryDb', // Nama database (opsional)
      );
    }
    // Jika sudah ada instance, kembalikan instance yang ada
    return Future.value(Isar.getInstance('libraryDb')!);
  }

  // --- Contoh Operasi CRUD dan Relasi ---

  // Tambah Genre Awal (jika belum ada)
  Future<void> addInitialAuthors() async {
    final isar = await db;
    // Cek apakah genre sudah ada
    final count = await isar.authors.count();
    if (count == 0) {
      print("Menambahkan genre awal...");
      final farel = Author(name: 'Farel', hometown: 'Malang');
      final arya = Author(name: 'Arya', hometown: 'Blitar');
      final wendy = Author(name: 'Wendy', hometown: 'Banyuwangi');
      final ipan = Author(name: 'Ipan', hometown: 'Kediri');

      await isar.writeTxn(() async {
        await isar.authors.putAll([farel, arya, wendy, ipan]);
      });
      print("Genre awal ditambahkan.");
    } else {
      print("Genre sudah ada.");
    }
  }

  // Tambah Buku Baru dengan Relasi Genre
  Future<void> addBookWithAuthors(Book newBook, List<String> authorNames) async {
    final isar = await db;

    // 1. Cari objek Genre berdasarkan nama
    List<Author> genresToLink = [];
    for (String name in authorNames) {
      final genre = await isar.authors.filter().nameEqualTo(name).findFirst();
      if (genre != null) {
        genresToLink.add(genre);
      } else {
        print("Peringatan: Author '$name' tidak ditemukan.");
        // Opsional: Buat genre baru jika tidak ditemukan
        // final newGenre = Genre(name: name);
        // await isar.writeTxn(() async {
        //   await isar.genres.put(newGenre);
        // });
        // genresToLink.add(newGenre);
      }
    }

    // 2. Simpan buku dan tautkan genre dalam transaksi
    await isar.writeTxn(() async {
      // Simpan buku dulu
      await isar.books.put(newBook);
      print('Buku "${newBook.title}" disimpan dengan ID: ${newBook.id}');

      // Tambahkan link ke genre
      if (genresToLink.isNotEmpty) {
        newBook.authors.addAll(genresToLink);
        // Simpan perubahan pada link
        await newBook.authors.save();
        print('Genre ditautkan ke buku "${newBook.title}".');
      }
    });
  }

  // Ambil semua buku (dengan genre yang sudah dimuat)
  Future<List<Book>> getAllBooksWithAuthors() async {
    final isar = await db;
    final books = await isar.books.where().findAll();
    // Muat relasi genre untuk setiap buku
    for (var book in books) {
      await book.authors.load();
    }
    return books;
  }

  Future<List<Author>> getAllAuthorsWithBooks() async {
      final isar = await db;
      final authors = await isar.authors.where().findAll();
      // Muat relasi buku untuk setiap genre
      for (var author in authors) {
          await author.books.load();
      }
      return authors;
  }

  // Contoh: Tambahkan buku contoh
  Future<void> addSampleBooks() async {
    final isar = await db;
    final bookCount = await isar.books.count();
    if (bookCount == 0) {
        final book1 = Book(
            title: 'The Lord of the Rings',
            publicationYear: 1954);
        await addBookWithAuthors(book1, ['Farel', 'Wendy']);

        final book2 = Book(
            title: 'Dune',
            publicationYear: 1965);
        await addBookWithAuthors(book2, ['Farel', 'Arya']);

         final book3 = Book(
            title: 'The Da Vinci Code',
            publicationYear: 2003);
        await addBookWithAuthors(book3, ['Farel', 'Ipan']);
         print("Buku contoh ditambahkan.");
    } else {
         print("Buku contoh sudah ada.");
    }
  }

  // Bersihkan database (hati-hati menggunakan ini!)
  Future<void> cleanDb() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.clear();
    });
    print("Database dibersihkan.");
  }

  // Update an existing book
  Future<void> updateBook(Book book, List<String> authorNames) async {
    final isar = await db;
    
    // Find authors to link
    List<Author> authorsToLink = [];
    for (String name in authorNames) {
      final author = await isar.authors.filter().nameEqualTo(name).findFirst();
      if (author != null) {
        authorsToLink.add(author);
      } else {
        print("Warning: Author '$name' not found");
      }
    }
    
    await isar.writeTxn(() async {
      // Save book first
      await isar.books.put(book);
      
      // Clear existing links and add new ones
      await book.authors.reset();
      book.authors.addAll(authorsToLink);
      await book.authors.save();
    });
    print('Book "${book.title}" updated with ID: ${book.id}');
  }
  
  // Delete book by ID
  Future<void> deleteBook(int bookId) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final success = await isar.books.delete(bookId);
      if (success) {
        print('Book with ID $bookId deleted successfully');
      } else {
        print('Failed to delete book with ID $bookId');
      }
    });
  }
}