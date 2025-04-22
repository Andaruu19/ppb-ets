import 'package:flutter/material.dart';
import '../services/isar_services.dart'; 
import '../models/book.dart';
import '../models/genre.dart';

class HomeScreen extends StatefulWidget {
  final IsarService isarService; // Terima service via constructor

  const HomeScreen({Key? key, required this.isarService}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> _books = [];
  List<Genre> _genres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Ambil data dari IsarService
      _books = await widget.isarService.getAllBooksWithGenres();
      _genres = await widget.isarService.getAllGenresWithBooks();
    } catch (e) {
      // Handle error (misalnya tampilkan snackbar)
      print("Error loading data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat data: $e")),
      );
    } finally {
      if (mounted) { // Pastikan widget masih ada di tree
         setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Isar Book Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Muat Ulang Data',
          ),
          // Tombol untuk menghapus data (hati-hati)
          // IconButton(
          //   icon: const Icon(Icons.delete_forever),
          //   onPressed: () async {
          //     await widget.isarService.cleanDb();
          //     _loadData(); // Muat ulang setelah membersihkan
          //   },
          //   tooltip: 'Hapus Semua Data',
          // ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator( // Tambahkan pull-to-refresh
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionTitle('Buku (${_books.length})'),
                  _buildBookList(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Genre (${_genres.length})'),
                  _buildGenreList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  Widget _buildBookList() {
    if (_books.isEmpty) {
      return const Center(child: Text('Belum ada buku.'));
    }
    return ListView.builder(
      shrinkWrap: true, // Penting dalam ListView utama
      physics: const NeverScrollableScrollPhysics(), // Non-scrollable
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        // Ambil nama genre dari link yang sudah di-load
        final genreNames = book.genres.map((g) => g.name ?? 'N/A').join(', ');
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            title: Text(book.title ?? 'Tanpa Judul'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('oleh ${book.author ?? 'Anonim'} (${book.publicationYear ?? 'N/A'})'),
                if (genreNames.isNotEmpty)
                  Text('Genre: $genreNames', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
            isThreeLine: genreNames.isNotEmpty,
          ),
        );
      },
    );
  }

   Widget _buildGenreList() {
    if (_genres.isEmpty) {
      return const Center(child: Text('Belum ada genre.'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _genres.length,
      itemBuilder: (context, index) {
        final genre = _genres[index];
        // Hitung jumlah buku dari link yang sudah di-load
        final bookCount = genre.books.length;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            title: Text(genre.name ?? 'Tanpa Nama'),
            subtitle: Text('Memiliki $bookCount buku'),
             // Opsional: Tampilkan daftar judul buku dalam genre ini
            trailing: IconButton(
              icon: Icon(Icons.list),
              onPressed: () {
                final bookTitles = genre.books.map((b) => b.title ?? 'N/A').join('\n- ');
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Buku dalam Genre "${genre.name}"'),
                    content: Text(bookTitles.isNotEmpty ? '- $bookTitles' : 'Tidak ada buku.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}