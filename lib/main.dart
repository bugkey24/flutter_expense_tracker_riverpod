import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

// Import our model, constants, and the new home screen
import 'features/transactions/data/constants.dart';
import 'features/transactions/data/models/transaction_model.dart';
import 'features/transactions/presentation/screens/home_screen.dart';

/// The main entry point for the application.
Future<void> main() async {
  // --- 1. Platform Binding Initialization ---
  WidgetsFlutterBinding.ensureInitialized();

  // --- 2. Hive Database Initialization ---
  final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // --- 3. Hive Adapter Registration ---
  Hive.registerAdapter(TransactionModelAdapter());

  // --- 4. Open Hive Box ---
  await Hive.openBox<TransactionModel>(kTransactionBoxName);

  // --- 5. Initialize Date Formatting ---
  await initializeDateFormatting('id_ID', null);

  // --- 6. Run the Application ---
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  /// Creates the main application widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Expense Tracker',
      debugShowCheckedModeBanner: false, // Disables the debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(), // Set the home screen
    );
  }
}
