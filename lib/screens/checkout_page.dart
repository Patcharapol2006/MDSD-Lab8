import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_model.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('ตะกร้าสินค้า')),
      body: cart.items.isEmpty
          ? const Center(child: Text('ยังไม่มีสินค้าในตะกร้า'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
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
                          tooltip: 'นำออกจากตะกร้า',
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () =>
                              context.read<CartModel>().remove(item),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'รวมทั้งหมด: ${cart.totalPrice.toStringAsFixed(2)} บาท',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: cart.clear,
                          child: const Text('ล้างตะกร้า'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
