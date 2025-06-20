# โปรแกรมเยี่ยมบ้านนักเรียน (Student Home Visit App)

แอปพลิเคชัน Flutter สำหรับจัดการข้อมูลการเยี่ยมบ้านนักเรียน พร้อมฟีเจอร์การบันทึกที่อยู่จาก Google Maps และการถ่ายภาพ

## ฟีเจอร์หลัก

### 1. จัดการข้อมูลนักเรียน
- เพิ่ม แก้ไข ลบข้อมูลนักเรียน
- บันทึกรูปโปรไฟล์นักเรียน
- ข้อมูลพื้นฐาน: ชื่อ-สกุล, รหัสนักเรียน, โรงเรียน, ชั้น, ห้อง

### 2. จัดการที่อยู่บ้าน
- **นำเข้าสถานที่จาก Google Maps**: แปลง URL ที่แชร์จาก Google Maps, Facebook หรือ Line
- **ประเภทที่อยู่**: 
  - บ้านที่อาศัยอยู่กับพ่อแม่ (เป็นเจ้าของ/เช่า)
  - บ้านของญาติ/ผู้ปกครองที่ไม่ใช่ญาติ
  - บ้านหรือที่พักประเภท วัด มูลนิธิ หอพัก โรงงาน อยู่กับนายจ้าง
- **สถานที่ใกล้เคียง**: บันทึกสถานที่สำคัญรอบบ้านนักเรียน
- **พิกัด GPS**: บันทึกตำแหน่งที่แม่นยำ

### 3. การเยี่ยมบ้าน
- บันทึกวันที่และเวลาการเยี่ยม
- บันทึกวัตถุประสงค์และผลการเยี่ยม
- **ถ่ายภาพบ้าน**: สำหรับบันทึกหลักฐานการเยี่ยม
- **ภาพนักเรียนกับป้ายโรงเรียน**: สำหรับกรณีที่ถ่ายภาพบ้านไม่ได้

### 4. แผนที่
- แสดงตำแหน่งบ้านนักเรียนทั้งหมดบนแผนที่
- หมุดสีต่างกันตามประเภทที่อยู่
- เปิดใน Google Maps ได้โดยตรง

## การติดตั้งและใช้งาน

### ข้อกำหนดเบื้องต้น
- Flutter SDK
- Android Studio / VS Code
- Google Maps API Key

### การติดตั้ง

1. **Clone หรือ Download โปรเจค**
```bash
git clone [repository-url]
cd findhomestudent
```

2. **ติดตั้ง Dependencies**
```bash
flutter pub get
```

3. **ตั้งค่า Google Maps API Key**
   - สร้าง Google Cloud Project และเปิดใช้งาน Maps SDK
   - สร้าง API Key
   - แก้ไขไฟล์ `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_ACTUAL_API_KEY_HERE" />
   ```
   - แก้ไขไฟล์ `lib/services/location_service.dart`:
   ```dart
   static const String _placesApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

4. **รันแอป**
```bash
flutter run
```

## โครงสร้างโปรเจค

```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
│   ├── student.dart
│   ├── home_address.dart
│   └── visit.dart
├── services/                 # Business logic
│   ├── database_service.dart
│   └── location_service.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── student_list_screen.dart
│   ├── add_student_screen.dart
│   ├── student_detail_screen.dart
│   ├── add_address_screen.dart
│   ├── visit_screen.dart
│   └── map_screen.dart
```

## Dependencies สำคัญ

- `google_maps_flutter`: แสดงแผนที่
- `location` & `geolocator`: บริการตำแหน่ง
- `geocoding`: แปลงพิกัดเป็นที่อยู่
- `image_picker`: ถ่าย/เลือกภาพ
- `sqflite`: ฐานข้อมูล SQLite
- `http`: HTTP requests
- `url_launcher`: เปิด URL ภายนอก
#   f i n d h o m e s t u d e n t  
 