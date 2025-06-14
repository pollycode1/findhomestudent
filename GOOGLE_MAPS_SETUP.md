# การตั้งค่า Google Maps API สำหรับแอปเยี่ยมบ้านนักเรียน

## ขั้นตอนการสร้าง Google Cloud Project และ API Key

### 1. สร้าง Google Cloud Project

1. ไปที่ [Google Cloud Console](https://console.cloud.google.com/)
2. เข้าสู่ระบบด้วย Google Account
3. กดปุ่ม "Create Project" หรือ "สร้างโปรเจค"
4. ตั้งชื่อโปรเจค เช่น "Student-Home-Visit-App"
5. กดปุ่ม "Create"

### 2. เปิดใช้งาน APIs ที่จำเป็น

ในโปรเจคที่สร้างใหม่ ให้เปิดใช้งาน APIs ต่อไปนี้:

1. **Maps SDK for Android**
   - ไปที่ "APIs & Services" > "Library"
   - ค้นหา "Maps SDK for Android"
   - กดปุ่ม "Enable"

2. **Geocoding API**
   - ค้นหา "Geocoding API"
   - กดปุ่ม "Enable"

3. **Places API**
   - ค้นหา "Places API"
   - กดปุ่ม "Enable"

### 3. สร้าง API Key

1. ไปที่ "APIs & Services" > "Credentials"
2. กดปุ่ม "+ CREATE CREDENTIALS"
3. เลือก "API key"
4. คัดลอก API Key ที่ได้

### 4. จำกัดการใช้งาน API Key (แนะนำ)

1. กดปุ่ม "Restrict Key" หรือกดชื่อ API Key ที่สร้าง
2. ในส่วน "Application restrictions":
   - เลือก "Android apps"
   - กดปุ่ม "Add an item"
   - ใส่ Package name: `com.example.findhomestudent`
   - ใส่ SHA-1 certificate fingerprint (ดูวิธีการดูด้านล่าง)
3. ในส่วน "API restrictions":
   - เลือก "Restrict key"
   - เลือก APIs ที่ต้องการ:
     - Maps SDK for Android
     - Geocoding API
     - Places API
4. กดปุ่ม "Save"

### 5. ดู SHA-1 Certificate Fingerprint

เปิด Terminal/Command Prompt และรันคำสั่ง:

```bash
# สำหรับ Windows
cd C:\Users\%USERNAME%\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android

# สำหรับ Mac/Linux
cd ~/.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

หา SHA-1 fingerprint ในผลลัพธ์และคัดลอกมาใส่ในการตั้งค่า API Key

### 6. ใส่ API Key ในแอป

#### สำหรับ Android
แก้ไขไฟล์ `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE" />
```

#### สำหรับ Location Service
แก้ไขไฟล์ `lib/services/location_service.dart`:

```dart
static const String _placesApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
```

## การตรวจสอบการใช้งานและค่าใช้จ่าย

### 1. ตรวจสอบ Quota และการใช้งาน

1. ไปที่ Google Cloud Console
2. เลือกโปรเจคของคุณ
3. ไปที่ "APIs & Services" > "Dashboard"
4. ดูการใช้งาน APIs แต่ละตัว

### 2. ตั้งค่า Billing Alert

1. ไปที่ "Billing" > "Budgets & alerts"
2. กดปุ่ม "Create Budget"
3. ตั้งค่าจำนวนเงินที่ต้องการแจ้งเตือน
4. ตั้งค่าอีเมลแจ้งเตือน

### 3. อัตราค่าใช้จ่าย (ณ เวลาที่เขียน)

- **Maps SDK for Android**: ฟรี 28,000 map loads/เดือน
- **Geocoding API**: ฟรี 40,000 requests/เดือน  
- **Places API**: ฟรี 1,000 requests/เดือน

*อัตราอาจเปลี่ยนแปลง กรุณาตรวจสอบที่ [Google Maps Pricing](https://cloud.google.com/maps-platform/pricing)*

## การแก้ไขปัญหาที่พบบ่อย

### 1. แผนที่ไม่แสดง
- ตรวจสอบ API Key ใน AndroidManifest.xml
- ตรวจสอบว่าเปิดใช้งาน Maps SDK for Android แล้ว
- ตรวจสอบ Package name และ SHA-1 fingerprint

### 2. Geocoding ไม่ทำงาน  
- ตรวจสอบ API Key ใน location_service.dart
- ตรวจสอบว่าเปิดใช้งาน Geocoding API แล้ว
- ตรวจสอบการเชื่อมต่อ internet

### 3. Places API ไม่ทำงาน
- ตรวจสอบว่าเปิดใช้งาน Places API แล้ว
- ตรวจสอบ quota ว่าไม่เกินขำหนด
- ตรวจสอบรูปแบบ request

### 4. API Key ถูกปฏิเสธ
- ตรวจสอบการตั้งค่า restrictions
- ตรวจสอบ Package name ให้ตรงกัน
- ลองสร้าง API Key ใหม่

## Security Best Practices

1. **อย่าฝัง API Key ใน source code** ที่จะ commit ลง repository
2. **ใช้ API Key restrictions** เสมอ
3. **Monitor การใช้งาน** เป็นประจำ
4. **Rotate API Key** เป็นระยะ
5. **ใช้ Environment Variables** สำหรับ API Key ใน production

## ตัวอย่างการใช้ Environment Variables

สร้างไฟล์ `.env` (อย่า commit เข้า git):
```
GOOGLE_MAPS_API_KEY=your_actual_api_key_here
```

ใช้ package `flutter_dotenv` เพื่ออ่านค่าจากไฟล์ .env

## การ Deploy

เมื่อ deploy แอปจริง ให้:
1. สร้าง API Key ใหม่สำหรับ production
2. ใช้ SHA-1 จาก release keystore
3. ตั้งค่า restrictions ให้เข้มงวด
4. Monitor การใช้งานอย่างใกล้ชิด
