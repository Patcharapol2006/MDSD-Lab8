# Campus Marketplace — Week 7

แอป Flutter สำหรับใบงานสัปดาห์ที่ 7 เชื่อม Gemini API เพื่อวิเคราะห์รูปสินค้า
และสร้างร่างประกาศที่ผู้ใช้ตรวจทาน/แก้ไขก่อนยืนยัน

## ฟีเจอร์

- โหลดสินค้าจาก Fake Store API และเพิ่ม/ลบสินค้าในตะกร้า
- Bottom Navigation Bar ระหว่างหน้าหลักกับหน้าลงประกาศ
- เลือกรูปจากคลังภาพด้วย `image_picker`
- ส่งรูปและ Prompt ไปยัง Gemini แบบ multimodal
- บังคับ Structured Output ด้วย `responseSchema` และแปลงเป็น `ListingDraft`
- แสดง loading, timeout, API error, quota error และ safety-block error
- ให้ผู้ใช้แก้ไขชื่อ หมวดหมู่ และคำบรรยายก่อนยืนยันร่าง
- เก็บร่างล่าสุดไว้ใน State และล้างรูป/ฟอร์มหลังยืนยัน

## วิธีรัน

ใช้ Android Emulator หรือ iOS Simulator (โค้ดรูปภาพใช้ `dart:io` จึงไม่รองรับ Web)

```bash
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY
```

ห้ามใส่ API key จริงใน source code หรือ commit ขึ้น Git

## ตรวจสอบโค้ด

```bash
flutter analyze
flutter test
```

การทดสอบ Gemini จริงต้องใช้ API key และรูปสินค้าใน Emulator/Simulator ส่วน widget
test ใช้ repository ปลอม จึงไม่เรียกเครือข่าย

โมเดลเริ่มต้นคือ `gemini-3.5-flash` และสามารถเปลี่ยนตอนรันได้โดยไม่ต้องแก้ source:

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY --dart-define=GEMINI_MODEL=MODEL_ID
```
