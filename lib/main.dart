import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- 1. IMPORT THIS
import 'package:path_provider/path_provider.dart' as path_provider;

// Import our model, constants, and the new home screen
import 'features/transactions/data/constants.dart';
import 'features/transactions/data/models/transaction_model.dart';
import 'features/transactions/presentation/screens/home_screen.dart';

/// The main entry point for the application.
Future<void> main() async {
  // --- 1. Platform Binding Initialization ---
  // Ensure that Flutter bindings are initialized before calling native code.
  // This is mandatory for async operations in main().
  WidgetsFlutterBinding.ensureInitialized();

  // --- 2. Hive Database Initialization ---
  // Get the application's local document directory using path_provider.
  final appDocumentDir =
      await path_provider.getApplicationDocumentsDirectory();

  // Initialize Hive in the app's document directory.
  await Hive.initFlutter(appDocumentDir.path);

  // --- 3. Hive Adapter Registration ---
  // Register the generated adapter for the TransactionModel.
  // This allows Hive to understand how to read/write the object.
  Hive.registerAdapter(TransactionModelAdapter());

  // --- 4. Open Hive Box ---
  // Open the box where TransactionModel objects will be stored.
  await Hive.openBox<TransactionModel>(kTransactionBoxName);

  // --- 5. Initialize Date Formatting ---
  // This loads the localization data for the 'id_ID' locale.
  // We must call this before using DateFormat from the intl package.
  await initializeDateFormatting('id_ID', null); // <-- 2. ADD THIS LINE

  // --- 6. Run the Application ---
  // Run the app within a ProviderScope for Riverpod state management.
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