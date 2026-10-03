import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryApi implements ItemRepository {
  static const _baseUrl = 'https://fakestoreapi.com/products';

  // ใช้เฉพาะเมื่อ Fake Store API ล่มหรือ Emulator ต่ออินเทอร์เน็ตไม่ได้
  // เพื่อให้ยังทดสอบหน้า Home และตะกร้าสินค้าได้ตามใบงาน
  static const _fallbackItems = [
    Item(
      id: -1,
      title: 'หนังสือ Flutter มือสอง (ข้อมูลสำรอง)',
      price: 250,
      description: 'หนังสือฝึกพัฒนาแอป Flutter สภาพดี',
      category: 'หนังสือเรียน',
      imageUrl: 'assets/products/flutter_book.png',
    ),
    Item(
      id: -2,
      title: 'หูฟังไร้สาย (ข้อมูลสำรอง)',
      price: 490,
      description: 'หูฟังสำหรับเรียนออนไลน์และฟังเพลง',
      category: 'อุปกรณ์อิเล็กทรอนิกส์',
      imageUrl: 'assets/products/headphones.jpg',
    ),
    Item(
      id: -3,
      title: 'โคมไฟตั้งโต๊ะ (ข้อมูลสำรอง)',
      price: 180,
      description: 'โคมไฟขนาดกะทัดรัด เหมาะสำหรับโต๊ะอ่านหนังสือ',
      category: 'ของแต่งหอพัก',
      imageUrl: 'assets/products/desk_lamp.jpg',
    ),
  ];

  @override
  Future<List<Item>> getItems() async {
    final uri = Uri.parse(_baseUrl);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((value) => Item.fromJson(value as Map<String, dynamic>))
            .toList();
      }
      return _fallbackItems;
    } on TimeoutException {
      return _fallbackItems;
    } on http.ClientException {
      return _fallbackItems;
    } on FormatException {
      return _fallbackItems;
    }
  }
}
