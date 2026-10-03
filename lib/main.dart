import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/cart_model.dart';
import 'repositories/item_repository_api.dart';
import 'screens/main_scaffold.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => CartModel(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: MainScaffold(repository: ItemRepositoryApi()),
    );
  }
}
