# 📈 บันทึกความคืบหน้าการพัฒนา (Development Progress) — V-Breaker

> เอกสารนี้ใช้บันทึกประวัติการทำงาน การตัดสินใจสำคัญ และความคืบหน้าของโปรเจกต์ในแต่ละวัน (Devlog)

---

## 📅 [2026-05-16] — Project Setup & GDD Creation
**สถานะปัจจุบัน:** Phase 0 (เสร็จสิ้น) ➡️ กำลังเข้าสู่ Phase 1

### ภารกิจที่ทำสำเร็จ (Completed Work):
1. **จัดทำ Game Design Document (GDD):**
   - รวบรวมแนวคิดจาก `plague_simulator_GDD.md` และโครงสร้างจาก `GDD_Template.md` สู่ไฟล์ `Main_GDD.md`
   - กำหนดวิสัยทัศน์ของเกมในฐานะ Idle/Incremental Simulator ที่มีกลิ่นอายล้อเลียนฮีโร่ (The Boys)
2. **ประยุกต์ใช้ทักษะ Game Designer (Viral Spectacle & Juice):**
   - วางแผนงานภาพที่เน้นความสะใจ เช่น กฎ 3 วินาทีแรก (Entrance Flash/Slam-in), ระบบ Screen Shake, Hit Freeze 60ms, และ Combo Pop-ups
   - เน้นให้หน้าจอมีการเคลื่อนไหวตลอดเวลา (Motion Every Frame) ด้วยสปอร์พิษและ Color Cycling
3. **กำหนดชื่อและโครงสร้างโปรเจกต์:**
   - สรุปใช้ชื่อเกม **"V-Breaker"** อย่างเป็นทางการ
   - แก้ไขชื่อโปรเจกต์ใน `default.project.json` และจัดการทำความสะอาดไฟล์ GDD เดิม
4. **จัดทำระบบติดตามงาน (Task & Progress Tracking):**
   - สร้างไฟล์ `task.md` เพื่อแบ่ง Phase การทำงานอย่างละเอียด
   - สร้างไฟล์ `development_progress.md` เพื่อบันทึก Devlog

### แผนงานถัดไป (Next Steps):
- เริ่มต้นพัฒนา **Phase 1: Prototype**
  - วางโครงสร้างสคริปต์ใน `ServerScriptService` (เน้น `InfectionEngine.lua` และ `NPCSpawner.lua`)
  - สร้างโมเดล/Part พื้นฐานสำหรับ NPC สัตว์ (Tier 1) และทดสอบระบบแพร่เชื้อเบื้องต้น

---

## 📅 [2026-05-16] — Infection Engine & Player Service (Core Loop)
**สถานะปัจจุบัน:** Phase 1 (กำลังดำเนินการ)

### ภารกิจที่ทำสำเร็จ (Completed Work):
1. **พัฒนาระบบ `PlayerService.lua`:**
   - จัดการข้อมูล Bio Points และ DNA Points ของผู้เล่นแต่ละคน
   - เพิ่มระบบคำนวณสะสม Bio Points เพื่อแปลงเป็น DNA Points (ทุกๆ 50 Bio Points รับ 5 DNA Points) พร้อมส่ง Event แจ้งเตือน Client
2. **พัฒนาระบบ `InfectionEngine.lua`:**
   - สร้างระบบรับคำสั่ง `REQUEST_INFECT` จาก Client เพื่อปล่อยเชื้อใส่ NPC ตัวแรก
   - สร้างลูปอัตโนมัติ (StartLoop) คำนวณการแพร่เชื้อจากตัวที่ติดเชื้อไปยังตัวที่ยังไม่ติดเชื้อในรัศมี `BASE_SPREAD_RADIUS` (15 studs)
   - คำนวณโอกาสติดเชื้อตาม `ImmuneStrength` ของเป้าหมายแต่ละ Tier
   - เปลี่ยนสี Part ของเป้าหมายเป็นสีเขียวเรืองแสง (Toxic Green + Neon Material) ทันทีที่ติดเชื้อ
   - มอบ Bio Points ให้เจ้าของเชื้อ และส่ง Event แจ้ง Client เพื่อแสดง Pop-up และเล่น Particle/Sound
3. **ปรับปรุง `Constants.lua` และ `ServerMain.server.lua`:**
   - อัปเดตค่าคงที่และรายชื่อ Remote Events ทั้งหมดสำหรับ V-Breaker
   - เชื่อมต่อการทำงานของ Service ใน ServerMain

### แผนงานถัดไป (Next Steps):
- พัฒนาระบบ **NPC Spawner (`NPCSpawner.lua`)** สำหรับสุ่มเกิด NPC สัตว์ (Tier 1) พร้อม AI เดินสุ่ม
- พัฒนาระบบ **Client UI & Visuals** (แสดงผลหลอด Bio/DNA, เล่น Particle สีเขียว และ Screen Shake)

---

## 📅 [2026-05-16] — NPC Spawner & AI Movement (Tier 1)
**สถานะปัจจุบัน:** Phase 1 (ใกล้เสร็จสมบูรณ์)

### ภารกิจที่ทำสำเร็จ (Completed Work):
1. **พัฒนาระบบ `NPCSpawner.lua`:**
   - สร้างโฟลเดอร์ `workspace.NPCs` และลบหุ่น Dummy เก่าออกเพื่อเตรียมพื้นที่ให้สัตว์ที่มี AI
   - สร้างพื้นที่ `ForestZone_SpawnArea` (สีเขียวป่าไม้โปร่งแสง) เป็นโซนสำหรับเกิดสัตว์ Tier 1
   - เพิ่มลูปสุ่มเกิดอัตโนมัติ (StartSpawnerLoop) ควบคุมประชากรสูงสุด 15 ตัว โดยใช้อัตราส่วน SpawnWeight (Rat 50%, Bird 25%, Pig 15%, Monkey 10%)
2. **ระบบ AI และพฤติกรรมสัตว์ (Animal AI & Thematic Identity):**
   - **Rat & Pig:** เดินสุ่มบนพื้นป่า
   - **Bird:** บินสุ่มในอากาศระดับความสูง 12-25 studs
   - **Monkey:** มี AI หลบหนี (Fleeing AI) เมื่อเห็น NPC ที่ติดเชื้อในระยะ 30 studs จะวิ่งหนีไปทิศตรงข้ามทันที
   - **Expression Reactive:** ติดตั้ง BillboardGui แสดง Emoji บนหัวสัตว์ (`🐭`, `🐦`, `🐷`, `🐵`) และเมื่อติดเชื้อจะเปลี่ยนหน้าเป็น `🤢` ทันทีเพื่อเพิ่มอารมณ์ขันและความชัดเจน
3. **ปรับปรุง `Constants.lua` และ `ServerMain.server.lua`:**
   - เพิ่มตาราง `Constants.ANIMALS` เก็บค่าสถานะ (ความเร็ว, ภูมิคุ้มกัน, แต้ม Bio) ของสัตว์แต่ละชนิด
   - เชื่อมต่อและเปิดใช้งาน `NPCSpawner.Init()` ใน ServerMain

### แผนงานถัดไป (Next Steps):
- พัฒนาระบบ **Client UI & Visuals** (ปรับแต่งหน้าต่าง Main HUD, เพิ่มระบบ Screen Shake และเสียงเอฟเฟกต์) เพื่อปิดจบ Phase 1

---

## 📅 [2026-05-16] — Main HUD & Visual Juice (Phase 1 Complete)
**สถานะปัจจุบัน:** Phase 1 (เสร็จสมบูรณ์ 100%) ➡️ กำลังเข้าสู่ Phase 2

### ภารกิจที่ทำสำเร็จ (Completed Work):
1. **พัฒนาระบบ `MainHUD.lua` (Premium UI Module):**
   - **Glassmorphism Design:** ออกแบบหน้าต่างแผงควบคุมด้านล่างด้วยพื้นหลังกึ่งโปร่งแสง พร้อมกรอบ `UIStroke` สีเขียวเรืองแสงและเงาสะท้อน (Glow Effect) สไตล์พรีเมียม
   - **Juice & Micro-animations:** เพิ่มอนิเมชันขยายตัวอักษรและเด้งกลับ (TweenService) ทุกครั้งที่ Bio Points หรือ DNA Points มีการเปลี่ยนแปลง
   - **Progress Bar:** เพิ่มหลอดความคืบหน้าสะสม Bio Points สู่การรับ DNA Point ถาวร (แสดงตัวเลขชัดเจน เช่น `34 / 50`)
   - **Notification & Tip Bar:** ป้ายแจ้งเตือนด้านบนจอพร้อมระบบเขย่า (UI Shake) เมื่อเกิดข้อผิดพลาด (เช่น ไวรัสติดคูลดาวน์)
   - **Floating Pop-ups:** ระบบตัวเลขลอยขึ้นจากเป้าหมายที่ติดเชื้อ (เช่น `+1 Bio`) พร้อมสุ่มองศาเอียงเล็กน้อยเพื่อเพิ่ม Game Feel
2. **ปรับปรุง `ClientMain.client.lua`:**
   - ปรับโครงสร้างสคริปต์ให้สะอาดและเรียกใช้ `MainHUD` เป็น Module
   - เชื่อมต่อระบบ Particle Emitter สีเขียวเรืองแสงเวลาเกิดการระบาด (`INFECTION_SPREAD`)
3. **Commit Git:**
   - บันทึกประวัติ Git ทั้งหมดของ Phase 1 ลง Repository สำเร็จ

### แผนงานถัดไป (Next Steps):
- เริ่มต้นพัฒนา **Phase 2: Alpha (Mutation & AI)**
  - สร้างระบบสายต้นไม้กลายพันธุ์ (`MutationTree.lua`) และร้านค้า Mutation Shop
  - สร้างระบบ AI รัฐบาล (`GovernmentAI.lua`) และระดับการเตือนภัย Threat Level

---
