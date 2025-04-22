import 'package:isar/isar.dart';
import 'package:flutter/material.dart';
import 'services/isar_services.dart';
import 'screens/home_screen.dart';

void main() async {
  // 1. Pastikan Flutter binding siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Isar Core (WAJIB untuk Flutter)
  //    Ini akan mendownload binary Isar yang sesuai untuk platform target.
  await Isar.initializeIsarCore(download: true);

  // 3. Buat instance IsarService (ini akan memicu pembukaan DB)
  final isarService = IsarService();

  // 4. (Opsional) Tambahkan data awal jika database baru dibuat
  //    Tunggu DB benar-benar terbuka sebelum menambahkan data
  await isarService.db; // Pastikan DB sudah siap
  await isarService.addInitialAuthors(); // Tambah genre jika belum ada
  await isarService.addSampleBooks();  // Tambah buku contoh jika belum ada


  // 5. Jalankan aplikasi Flutter
  runApp(MyApp(isarService: isarService));
}

class MyApp extends StatelessWidget {
  final IsarService isarService;

  const MyApp({Key? key, required this.isarService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isar Book Example',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(isarService: isarService), // Kirim service ke HomeScreen
      debugShowCheckedModeBanner: false,
    );
  }
}