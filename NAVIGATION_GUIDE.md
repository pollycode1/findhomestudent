# 🧭 คู่มือฟีเจอร์นำทางไปยังที่อยู่นักเรียน

## ภาพรวม
ฟีเจอร์ใหม่ที่ช่วยให้ครูสามารถใช้ Google Maps เพื่อนำทางไปยังที่อยู่ของนักเรียนได้อย่างง่ายดาย เมื่อกดปุ่ม "เริ่มเยี่ยมบ้าน"

## 🚀 ฟีเจอร์หลัก

### 1. ปุ่มนำทางในหน้าเยี่ยมบ้าน
- **ปุ่มในการ์ดที่อยู่**: "นำทางไปยังที่อยู่" 
- **FloatingActionButton**: "แผนที่และนำทาง"

### 2. ตัวเลือกการดูแผนที่
เมื่อกดปุ่มจะมี 2 ตัวเลือก:

#### 🧭 เริ่มเยี่ยมบ้าน (นำทาง)
- เปิด Google Maps พร้อมเส้นทางนำทาง
- ใช้โหมดขับรถ (driving mode)
- แสดงการยืนยันก่อนเปิดแอป

#### 🗺️ ดูตำแหน่งในแผนที่
- เปิด Google Maps เพื่อดูตำแหน่ง
- ไม่มีการนำทาง เป็นการดูอย่างเดียว

## 📱 วิธีการใช้งาน

### ขั้นตอนที่ 1: เข้าสู่หน้าเยี่ยมบ้าน
1. เลือกนักเรียนจากรายการ
2. ไปที่รายละเอียดนักเรียน
3. เลือกที่อยู่ที่ต้องการเยี่ยม
4. กด "เยี่ยมบ้าน" จากเมนู

### ขั้นตอนที่ 2: เริ่มการนำทาง
1. **วิธีที่ 1**: กดปุ่ม "นำทางไปยังที่อยู่" ในการ์ดข้อมูล
2. **วิธีที่ 2**: กด FloatingActionButton "แผนที่และนำทาง"
3. เลือกตัวเลือกที่ต้องการ:
   - **เริ่มเยี่ยมบ้าน (นำทาง)** สำหรับการนำทาง
   - **ดูตำแหน่งในแผนที่** สำหรับดูตำแหน่ง

### ขั้นตอนที่ 3: ยืนยันการนำทาง
1. ระบบจะแสดงหน้าต่างยืนยัน
2. ตรวจสอบที่อยู่ที่จะไป
3. กด "เริ่มนำทาง" เพื่อเปิด Google Maps

## 🔧 URL ที่ใช้

### สำหรับ Navigation (นำทาง)
```
https://www.google.com/maps/dir/?api=1&destination=lat,lng&travelmode=driving
```

### สำหรับดูตำแหน่ง
```
https://www.google.com/maps/search/?api=1&query=lat,lng
```

## ⚠️ ข้อกำหนด

### แอปที่จำเป็น
- **Google Maps**: ติดตั้งบนมือถือ (Android/iOS)
- หากไม่มี Google Maps จะเปิดผ่านเว็บเบราว์เซอร์

### สิทธิ์ที่ต้องการ
- สิทธิ์เปิดแอปภายนอก (External App Launch)
- การเชื่อมต่ออินเทอร์เน็ต

## 💡 เคล็ดลับการใช้งาน

### สำหรับครู
1. **ตรวจสอบก่อนออกเดินทาง**: ใช้ "ดูตำแหน่งในแผนที่" เพื่อดูตำแหน่งก่อน
2. **เริ่มนำทางเมื่อพร้อม**: ใช้ "เริ่มเยี่ยมบ้าน" เมื่อพร้อมออกเดินทาง
3. **ตรวจสอบเส้นทาง**: Google Maps จะแสดงเส้นทางที่เหมาะสม

### การใช้งานร่วมกับ Google Maps
1. **เปลี่ยนโหมดการเดินทาง**: ใน Google Maps สามารถเปลี่ยนจากรถยนต์เป็นมอเตอร์ไซค์หรือเดิน
2. **หลีกเลี่ยงการจราจร**: Google Maps จะแนะนำเส้นทางที่หลีกเลี่ยงการจราจร
3. **บันทึกตำแหน่ง**: สามารถบันทึกตำแหน่งใน Google Maps เพื่อใช้ในอนาคต

## 🔍 การแก้ไขปัญหา

### ❌ ไม่สามารถเปิด Google Maps ได้

**สาเหตุ:**
- ไม่ได้ติดตั้ง Google Maps
- Google Maps ถูกปิดใช้งาน

**แก้ไข:**
1. ติดตั้ง Google Maps จาก Play Store/App Store
2. เปิดใช้งาน Google Maps
3. ลองใหม่อีกครั้ง

### ❌ เปิดในเว็บเบราว์เซอร์แทน

**สาเหตุ:**
- Google Maps แอปไม่ได้กำหนดเป็นแอปเริ่มต้น

**แก้ไข:**
1. เปิด Google Maps แอป
2. ตั้งค่าให้เป็นแอปเริ่มต้นสำหรับแผนที่
3. ลองใช้ฟีเจอร์นำทางใหม่

### ❌ ตำแหน่งไม่ถูกต้อง

**สาเหตุ:**
- พิกัดที่บันทึกไว้ไม่ถูกต้อง

**แก้ไข:**
1. กลับไปที่หน้ารายละเอียดนักเรียน
2. แก้ไขที่อยู่
3. ใช้ฟีเจอร์ "นำเข้าจาก Google Maps" ใหม่

## 🆕 ฟีเจอร์เสริม

### การยืนยันการนำทาง
- แสดงข้อมูลที่อยู่ก่อนเปิด Google Maps
- ป้องกันการเปิดแอปโดยไม่ตั้งใจ

### การแสดงสถานะ
- แสดงข้อความสำเร็จเมื่อเปิด Google Maps ได้
- แสดงข้อความข้อผิดพลาดหากเกิดปัญหา

### UI ที่สวยงาม
- Bottom Sheet ที่ออกแบบมาใหม่
- ไอคอนและสีที่เหมาะสม
- ข้อความที่ชัดเจน

## 🔄 การอัปเดตในอนาคต

### ฟีเจอร์ที่กำลังพัฒนา
- **เลือกโหมดการเดินทาง**: รถยนต์, มอเตอร์ไซค์, เดิน
- **การบันทึกเส้นทาง**: บันทึกเส้นทางที่ใช้บ่อย
- **แผนที่ออฟไลน์**: ดาวน์โหลดแผนที่สำหรับใช้ออฟไลน์
- **แชร์ตำแหน่ง**: ส่งตำแหน่งให้เพื่อนร่วมงาน

### การปรับปรุงที่คาดหวัง
- รองรับแอปแผนที่อื่น (Apple Maps, Waze)
- การแจ้งเตือนเมื่อถึงปลายทาง
- ประวัติการเยี่ยมบ้านพร้อมเส้นทาง

---

📝 **หมายเหตุ**: ฟีเจอร์นี้ทำงานร่วมกับ Google Maps เป็นหลัก แนะนำให้ติดตั้ง Google Maps เพื่อประสบการณ์การใช้งานที่ดีที่สุด
