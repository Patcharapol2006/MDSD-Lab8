import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../repositories/favorites_repository.dart';

class FavoritesPage extends StatefulWidget {
  final FavoritesRepository repository;
  final int refreshToken;

  const FavoritesPage({
    super.key,
    required this.repository,
    this.refreshToken = 0,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<FavoriteItem>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant FavoritesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _reload();
    }
  }

  void _reload() {
    _favoritesFuture = widget.repository.getAllFavorites();
  }

  Future<void> _remove(int itemId) async {
    try {
      await widget.repository.removeFavorite(itemId);
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบออกจากรายการโปรดแล้ว')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบรายการโปรดไม่สำเร็จ: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายการโปรด')),
      body: FutureBuilder<List<FavoriteItem>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('โหลดรายการโปรดไม่สำเร็จ: ${snapshot.error}'));
          }
          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีรายการโปรด ลองกดหัวใจที่หน้าหลักดูสิ'),
            );
          }
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              return ListTile(
                leading: _FavoriteImage(imageUrl: favorite.imageUrl),
                title: Text(favorite.title),
                subtitle: Text('${favorite.price.toStringAsFixed(2)} บาท'),
                trailing: IconButton(
                  tooltip: 'ลบรายการโปรด',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _remove(favorite.itemId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteImage extends StatelessWidget {
  final String imageUrl;

  const _FavoriteImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, width: 48, height: 48, fit: BoxFit.cover);
    }
    if (imageUrl.isEmpty) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.inventory_2_outlined),
      );
    }
    return Image.network(
      imageUrl,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
    );
  }
}
