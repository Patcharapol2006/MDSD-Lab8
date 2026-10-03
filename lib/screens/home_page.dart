import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_model.dart';
import '../models/item.dart';
import '../repositories/item_repository.dart';
import 'checkout_page.dart';

class HomePage extends StatefulWidget {
  final ItemRepository repository;

  const HomePage({super.key, required this.repository});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.repository.getItems();
  }

  void _retry() {
    setState(() {
      _itemsFuture = widget.repository.getItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          IconButton(
            tooltip: 'ตะกร้าสินค้า',
            icon: Badge(
              label: Text('${context.watch<CartModel>().itemCount}'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutPage()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'เกิดข้อผิดพลาด: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('ไม่พบสินค้า'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: item.imageUrl.startsWith('assets/')
                    ? Image.asset(
                        item.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : item.imageUrl.isEmpty
                    ? const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.inventory_2_outlined),
                      )
                    : Image.network(
                        item.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image),
                      ),
                title: Text(item.title),
                subtitle: Text('${item.price.toStringAsFixed(2)} บาท'),
                trailing: IconButton(
                  tooltip: 'เพิ่มลงตะกร้า',
                  icon: const Icon(Icons.add_shopping_cart),
                  onPressed: () {
                    context.read<CartModel>().add(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('เพิ่ม "${item.title}" ลงตะกร้าแล้ว'),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
