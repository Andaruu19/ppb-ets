import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/genre.dart';
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
        [BookSchema, GenreSchema], // Sertakan SEMUA skema di sini
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
  Future<void> addInitialGenres() async {
    final isar = await db;
    // Cek apakah genre sudah ada
    final count = await isar.genres.count();
    if (count == 0) {
      print("Menambahkan genre awal...");
      final fantasy = Genre(name: 'Fantasy');
      final sciFi = Genre(name: 'Science Fiction');
      final adventure = Genre(name: 'Adventure');
      final mystery = Genre(name: 'Mystery');

      await isar.writeTxn(() async {
        await isar.genres.putAll([fantasy, sciFi, adventure, mystery]);
      });
      print("Genre awal ditambahkan.");
    } else {
      print("Genre sudah ada.");
    }
  }

  // Tambah Buku Baru dengan Relasi Genre
  Future<void> addBookWithGenres(Book newBook, List<String> genreNames) async {
    final isar = await db;

    // 1. Cari objek Genre berdasarkan nama
    List<Genre> genresToLink = [];
    for (String name in genreNames) {
      final genre = await isar.genres.filter().nameEqualTo(name).findFirst();
      if (genre != null) {
        genresToLink.add(genre);
      } else {
        print("Peringatan: Genre '$name' tidak ditemukan.");
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
        newBook.genres.addAll(genresToLink);
        // Simpan perubahan pada link
        await newBook.genres.save();
        print('Genre ditautkan ke buku "${newBook.title}".');
      }
    });
  }

  // Ambil semua buku (dengan genre yang sudah dimuat)
  Future<List<Book>> getAllBooksWithGenres() async {
    final isar = await db;
    final books = await isar.books.where().findAll();
    // Muat relasi genre untuk setiap buku
    for (var book in books) {
      await book.genres.load();
    }
    return books;
  }

  // Ambil semua genre (dengan buku yang sudah dimuat)
  Future<List<Genre>> getAllGenresWithBooks() async {
      final isar = await db;
      final genres = await isar.genres.where().findAll();
      // Muat relasi buku untuk setiap genre
      for (var genre in genres) {
          await genre.books.load();
      }
      return genres;
  }

  // Contoh: Tambahkan buku contoh
  Future<void> addSampleBooks() async {
    final isar = await db;
    final bookCount = await isar.books.count();
    if (bookCount == 0) {
        print("Menambahkan buku contoh...");
        final book1 = Book(
            title: 'The Lord of the Rings',
            author: 'J.R.R. Tolkien',
            publicationYear: 1954);
        await addBookWithGenres(book1, ['Fantasy', 'Adventure']);

        final book2 = Book(
            title: 'Dune',
            author: 'Frank Herbert',
            publicationYear: 1965);
        await addBookWithGenres(book2, ['Science Fiction']);

         final book3 = Book(
            title: 'The Da Vinci Code',
            author: 'Dan Brown',
            publicationYear: 2003);
        await addBookWithGenres(book3, ['Mystery', 'Adventure']);
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
}