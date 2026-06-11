import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  configureDependencies(); // Setup DI
  
  runApp(const BudgetKosApp());
}
