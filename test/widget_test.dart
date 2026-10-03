import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:campus_marketplace_w7/models/cart_model.dart';
import 'package:campus_marketplace_w7/models/item.dart';
import 'package:campus_marketplace_w7/repositories/item_repository.dart';
import 'package:campus_marketplace_w7/screens/home_page.dart';

class _FakeItemRepository implements ItemRepository {
  @override
  Future<List<Item>> getItems() => Completer<List<Item>>().future;
}

void main() {
  testWidgets('แอปแสดงชื่อและสถานะกำลังโหลดสินค้า', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartModel(),
        child: MaterialApp(home: HomePage(repository: _FakeItemRepository())),
      ),
    );

    expect(find.text('Campus Marketplace'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
