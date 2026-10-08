# Campus Marketplace — Lab 8


## เทคโนโลยีที่ใช้

- Flutter และ Dart
- Drift และ SQLite
- Provider
- Fake Store API
- Gemini API
- Image Picker
- Repository Pattern

## โครงสร้างที่สำคัญ

```text
lib/
├── database/
│   ├── app_database.dart
│   ├── app_database.g.dart
│   └── tables.dart
├── models/
├── repositories/
│   ├── favorites_repository.dart
│   ├── favorites_repository_drift.dart
│   ├── listing_draft_repository.dart
│   └── listing_draft_repository_drift.dart
├── screens/
│   ├── favorites_page.dart
│   ├── home_page.dart
│   ├── main_scaffold.dart
│   ├── my_drafts_page.dart
│   └── sell_item_page.dart
└── services/
```

## การติดตั้ง

ติดตั้ง dependencies:

```bash
flutter pub get
```

สร้างโค้ดของ Drift หลังแก้ไข Schema:

```bash
dart run build_runner build
```

## วิธีรัน

รันแอปโดยไม่เปิดฟีเจอร์ Gemini:

```bash
flutter run
```

รันแอปพร้อม Gemini API:

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY
```

สามารถระบุ Gemini model เพิ่มเติมได้:

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY --dart-define=GEMINI_MODEL=MODEL_ID
```

> ห้ามใส่ API key จริงไว้ใน Source Code หรือ Commit ขึ้น GitHub

## การตรวจสอบโค้ด

```bash
flutter analyze
flutter test
```

ผลการตรวจสอบล่าสุด:

- `flutter analyze` — No issues found
- `flutter test` — All tests passed


