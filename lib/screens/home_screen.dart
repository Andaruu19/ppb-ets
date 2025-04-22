import 'package:flutter/material.dart';
import '../services/isar_services.dart'; 
import '../models/book.dart';
import '../models/author.dart';

class HomeScreen extends StatefulWidget {
  final IsarService isarService;

  const HomeScreen({Key? key, required this.isarService}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> _books = [];
  List<Author> _authors = [];
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
      _books = await widget.isarService.getAllBooksWithAuthors();
      _authors = await widget.isarService.getAllAuthorsWithBooks();
    } catch (e) {
      // Handle error (misalnya tampilkan snackbar)
      print("Error loading data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data: $e")),
        );
      }
    } finally {
      if (mounted) { // Pastikan widget masih ada di tree
         setState(() => _isLoading = false);
      }
    }
  }

  // Display dialog to add or edit a book
  Future<void> _showBookDialog({Book? book}) async {
    final isEditing = book != null;
    final titleController = TextEditingController(text: book?.title ?? '');
    final yearController = TextEditingController(
      text: book?.publicationYear?.toString() ?? ''
    );
    final synopsisController = TextEditingController(text: book?.synopsis ?? '');
    
    // Track selected authors
    final selectedAuthors = <String>[];
    
    // Initialize selected authors if editing
    if (isEditing && book.authors.isNotEmpty) {
      selectedAuthors.addAll(book.authors.map((a) => a.name ?? '').where((name) => name.isNotEmpty));
    }
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Buku' : 'Tambah Buku Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul'),
                ),
                TextField(
                  controller: yearController,
                  decoration: const InputDecoration(labelText: 'Tahun Terbit'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: synopsisController,
                  decoration: const InputDecoration(labelText: 'Sinopsis'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('Pilih Penulis:'),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _authors.length,
                    itemBuilder: (context, index) {
                      final author = _authors[index];
                      final isSelected = selectedAuthors.contains(author.name);
                      return CheckboxListTile(
                        title: Text(author.name ?? 'N/A'),
                        subtitle: Text(author.hometown ?? ''),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedAuthors.add(author.name!);
                            } else {
                              selectedAuthors.remove(author.name);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Judul harus diisi'))
                  );
                  return;
                }
                
                // Parse year
                int? year;
                if (yearController.text.isNotEmpty) {
                  year = int.tryParse(yearController.text);
                  if (year == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tahun harus berupa angka'))
                    );
                    return;
                  }
                }
                
                // Create or update book
                if (isEditing) {
                  // Update existing book
                  book.title = titleController.text;
                  book.publicationYear = year;
                  book.synopsis = synopsisController.text;
                  
                  await widget.isarService.updateBook(book, selectedAuthors);
                } else {
                  // Create new book
                  final newBook = Book(
                    title: titleController.text,
                    publicationYear: year,
                    synopsis: synopsisController.text,
                  );
                  
                  await widget.isarService.addBookWithAuthors(
                    newBook, 
                    selectedAuthors
                  );
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  _loadData(); // Refresh data
                }
              },
              child: Text(isEditing ? 'Simpan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Confirm and delete a book
  Future<void> _confirmDeleteBook(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: Text('Yakin ingin menghapus "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await widget.isarService.deleteBook(book.id);
      _loadData(); // Refresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Muat Ulang Data',
          ),
        ],
      ),
      // Add floating action button for adding new books
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBookDialog(),
        tooltip: 'Tambah Buku',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionTitle('Buku (${_books.length})'),
                  _buildBookList(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Penulis (${_authors.length})'),
                  _buildAuthorList(),
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
      return const Card(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Belum ada buku.', textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        final authorNames = book.authors.map((g) => g.name ?? 'N/A').join(', ');
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            title: Text(book.title ?? 'Tanpa Judul'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('(${book.publicationYear ?? 'N/A'})'),
                if (book.synopsis != null && book.synopsis!.isNotEmpty)
                  Text(
                    book.synopsis!,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (authorNames.isNotEmpty)
                  Text(
                    'Authors: $authorNames', 
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showBookDialog(book: book),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteBook(book),
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthorList() {
    if (_authors.isEmpty) {
      return const Card(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Belum ada penulis.', textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _authors.length,
      itemBuilder: (context, index) {
        final author = _authors[index];
        final bookCount = author.books.length;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            title: Text(author.name ?? 'Tanpa Nama'),
            subtitle: Text('Kota: ${author.hometown ?? 'N/A'} • Memiliki $bookCount buku'),
          ),
        );
      },
    );
  }
}