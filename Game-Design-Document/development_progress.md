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

## 📅 [2026-05-16] — Mutation Tree & Shop (Phase 2 Alpha)
**สถานะปัจจุบัน:** Phase 2 (กำลังดำเนินการ)

### ภารกิจที่ทำสำเร็จ (Completed Work):
1. **ออกแบบข้อมูลต้นไม้กลายพันธุ์ `MutationTree.lua` (Shared):**
   - แบ่งเป็น 3 สายหลัก: `Transmission` (Airborne, Waterborne, Zoonotic), `Symptoms` (Coughing, Sneezing, Fever, Lesions, Cytokine Storm), และ `Abilities` (Drug Resistance, Genetic Hardening, V-Corruptor)
   - กำหนดค่าสเตตัสอัปเกรด, ราคา (ใช้ DNA หรือ Bio Points), และเงื่อนไข Prerequisite (ต้องปลดล็อกขั้นก่อนหน้า)
2. **พัฒนาระบบ `MutationService.lua` (Server):**
   - จัดการข้อมูลการปลดล็อก Mutation ของผู้เล่นแต่ละคน พร้อมระบบตรวจสอบเงื่อนไขและหักแต้มผ่าน `PlayerService`
   - เชื่อมต่อฟังก์ชันคำนวณสเตตัสอัปเกรดเข้ากับ `InfectionEngine.lua` โดยตรง (เช่น เพิ่มรัศมีแพร่เชื้อ, ลด Tick Rate, เพิ่มโอกาสติดคริติคอล x5 Bio)
3. **สร้างหน้าต่าง UI `MutationShop.lua` (Client):**
   - **Premium Glassmorphism:** หน้าต่างร้านค้ากึ่งโปร่งแสง พร้อมแถบ Tab แยกหมวดหมู่ (`Transmission`, `Symptoms`, `Abilities`)
   - **Dynamic Cards:** การ์ดแสดงข้อมูลอัปเกรดพร้อมปุ่มกดซื้อที่เปลี่ยนสถานะอัตโนมัติ (`LOCKED`, `UNLOCKED`, `BUY`) ตามเงื่อนไขและเงินที่ผู้เล่นมี
   - **Smooth Animations:** ระบบเปิดปิดหน้าต่างและสลับ Tab ด้วย `TweenService`

### แผนงานถัดไป (Next Steps):
- พัฒนาระบบ **AI รัฐบาล (`GovernmentAI.lua`)** เพื่อคำนวณ Threat Level และการพัฒนางานวิจัยวัคซีน
- สร้าง **NPC มนุษย์ (Tier 2)** พร้อมระบบวิ่งหนีเมื่อเห็นคนติดเชื้อ

---

## 📅 [2026-05-17] — Tier 2 Human NPCs & City Zone Integration (Phase 2 Alpha Complete!)
**สถานะปัจจุบัน:** Phase 2 Alpha (เสร็จสมบูรณ์ 100%)

### ภารกิจที่ทำสำเร็จ (Completed Work):
1. **สร้างระบบสุ่มเกิดและ AI ของมนุษย์ Tier 2 (`NPCSpawner.lua` & `Constants.lua`):**
   - **City Zone Spawn Area:** สร้างพื้นที่เกิดใหม่สำหรับมนุษย์ (City Zone) ปูพื้นคอนกรีตสีเทาเคียงข้างพื้นที่ป่า
   - **Thematic Human Identities:** เพิ่มตัวละครมนุษย์ 3 อาชีพพร้อมเอกลักษณ์เฉพาะตัว:
     - `🧍 Citizen (ชาวบ้าน):` เลือด 200 HP, ภูมิต้านทาน 30, ให้รางวัล 5 Bio Points
     - `👨‍🔬 Scientist (นักวิทยาศาสตร์):` เลือด 200 HP, ภูมิต้านทาน 50, ให้รางวัล 8 Bio Points
     - `👮 Police (ตำรวจ):` เลือด 200 HP, ภูมิต้านทาน 75, ให้รางวัล 10 Bio Points
2. **ระบบ AI พฤติกรรมอัจฉริยะ (Thematic AI Reactions):**
   - **Panic & Fleeing (ชาวบ้าน/นักวิทย์):** เมื่อเห็นคนติดเชื้อในระยะ 40 studs หรือเมื่อตัวเองติดเชื้อ จะเปลี่ยนสีหน้าเป็น `😱` / `🤢` และวิ่งหนีสุดชีวิตด้วยความเร็ว x1.5
   - **Investigate & Zombie Patrol (ตำรวจ):** เมื่อยังไม่ติดเชื้อ จะวิ่งเข้าชาร์จหาคนติดเชื้อด้วยความเร็ว x1.3 เพื่อควบคุมสถานการณ์ แต่ถ้าติดเชื้อแล้วจะเปลี่ยนเป็นซอมบี้ `🧟` เดินลาดตระเวนช้าๆ (ความเร็ว x0.6)
3. **ระบบรองรับการคำนวณและ UI แบบไดนามิก (`InfectionEngine.lua` & `GovernmentAI.lua`):**
   - ปรับปรุงหลอดเลือดและป้ายสถานะบนหัวให้รองรับค่า MaxHealth (200 HP) และแสดงผล % หลอดเลือดได้อย่างถูกต้องแม่นยำ
   - รองรับระบบรางวัล Bio Points ตามความยากของเป้าหมายที่กำจัดได้แบบไดนามิก (เช่น ฆ่าตำรวจได้ +10 Bio Points ทันที)
   - เมื่อรัฐบาลปล่อยวัคซีน มนุษย์จะได้รับการรักษาและกลับสู่สถานะปกติพร้อมเปลี่ยน Emoji กลับตามอาชีพได้อย่างสมบูรณ์แบบ

### แผนงานถัดไป (Next Steps):
- เข้าสู่ **Phase 3 Beta** เต็มตัว: พัฒนาระบบบอสประจำโซน (Boss Manager) และการปลดล็อกแผนที่ (Map Progression)

---

## 📅 [2026-05-17] — Phase 3 Beta: Zone Boss Manager & Epic Health Bar Spectacles
**สถานะปัจจุบัน:** Phase 3 Beta (เริ่มต้นและเสร็จสิ้นระบบบอส)

### ภารกิจที่ทำสำเร็จ (Completed Work):
1. **สร้างระบบจัดการบอสประจำโซน (`BossManager.lua` & `Constants.lua`):**
   - **Thematic Boss Roster:** เพิ่มข้อมูลบอสระดับตำนาน 4 ตัวประจำโซนต่างๆ:
     - `⚡ Thunderclap (Forest Zone):` เลือด 1,000 HP, ภูมิต้านทาน 100, รางวัล 100 Bio / 10 DNA, สกิล `LightningStrike`
     - `🔥 Inferno (City Zone):` เลือด 2,500 HP, ภูมิต้านทาน 250, รางวัล 250 Bio / 25 DNA, สกิล `Firestorm`
     - `🌪️ Vortex (Military Base):` เลือด 5,000 HP, ภูมิต้านทาน 500, รางวัล 500 Bio / 50 DNA, สกิล `WindGust`
     - `🦸‍♂️ SUPREME (Vought HQ):` เลือด 10,000 HP, ภูมิต้านทาน 1,000, รางวัล 2,000 Bio / 200 DNA, สกิล `LaserEyes`
   - **Boss Spawning & AI Loop:** ระบบสุ่มเกิดบอสตามลำดับโซนทุกๆ 30 วินาที พร้อม AI เดินลาดตระเวนและปล่อย Particle เอฟเฟกต์สกิลพิเศษสุดอลังการ (Ability Spectacles)
2. **ระบบ UI หลอดเลือดบอสระดับบอสไฟต์ (`MainHUD.lua` & `ClientMain.client.lua`):**
   - **Epic Boss Bar Panel:** สร้างแผงหลอดเลือดบอสสีแดงเดือดกรอบทอง (`BossPanel`) ปรากฏที่ด้านบนของหน้าจอทันทีที่บอสเกิด พร้อมแสดงชื่อบอสและตัวเลข HP แบบเรียลไทม์
   - **Smooth Damage Tweens:** หลอดเลือดลดลงอย่างนุ่มนวลตามความเสียหายจริงผ่าน `TweenService`
3. **ระบบรางวัลระดับสูง (`InfectionEngine.lua`):**
   - เมื่อบอสถูกกำจัด ระบบจะมอบรางวัลใหญ่ทั้ง Bio Points และ DNA Points ทันที (เช่น `🧬 BOSS KILL! +10 DNA`) พร้อมส่ง Event ปิดหลอดเลือดบอสและแสดง Pop-up ประกาศชัยชนะกลางหน้าจอ

### แผนงานถัดไป (Next Steps):
- พัฒนาระบบ **การปลดล็อกโซนแผนที่ (Map Progression)** และระบบ **Prestige (จุติ)**

---

## 📅 [2026-05-17] — Phase 3 Beta: Map Progression & Tier 3 Elite Entities Integration
**สถานะปัจจุบัน:** Phase 3 Beta (เสร็จสิ้นระบบปลดล็อกแผนที่และบอสประจำโซน)

### ภารกิจที่ทำสำเร็จ (Completed Work):
1. **ระบบปลดล็อกโซนแผนที่ (Map Progression & Lifetime Bio Tracking):**
   - พัฒนาระบบติดตามแต้มสะสมตลอดชีพ (`LifetimeBioEarned`) ใน `PlayerService.lua` เพื่อใช้เป็นเกณฑ์ปลดล็อกโซนใหม่โดยไม่ถูกรีเซ็ตเมื่อแปลงเป็น DNA Points
   - **Zone Unlocking Thresholds:** กำหนดเกณฑ์การปลดล็อกโซนอย่างเป็นระบบ:
     - `🏙️ City Zone:` ปลดล็อกเมื่อสะสมครบ 1,000 Bio Points
     - `🪖 Military Base:` ปลดล็อกเมื่อสะสมครบ 5,000 Bio Points
     - `🦸‍♂️ Vought HQ:` ปลดล็อกเมื่อสะสมครบ 20,000 Bio Points
   - **Global Zone State:** สร้างฟังก์ชัน `PlayerService.IsZoneUnlocked(zoneName)` เพื่อให้ทุกระบบในเกมตรวจสอบสถานะการปลดล็อกได้ทันที
2. **ขยายพื้นที่เกิดและ NPC ระดับสูง Tier 3 (`NPCSpawner.lua` & `Constants.lua`):**
   - **Military Base & Vought HQ Spawn Areas:** สร้างพื้นที่เกิดใหม่สี Camo Green (Military) และ Dark Blue (Vought) เคียงข้างโซนเดิม
   - **Tier 3 Thematic Entities:** เพิ่ม NPC ทหารและซุปเปอร์ฮีโร่สุดแกร่ง:
     - `🪖 Soldier (ทหาร):` เลือด 300 HP, ภูมิต้านทาน 120, ให้รางวัล 25 Bio Points
     - `🛡️ Tank (รถถังหุ้มเกราะ):` เลือด 300 HP, ภูมิต้านทาน 250, ให้รางวัล 60 Bio Points
     - `🦹 Elite (ซุปเปอร์ฮีโร่ชั้นยอด):` เลือด 500 HP, ภูมิต้านทาน 400, ให้รางวัล 120 Bio Points, บินได้
     - `🦸 Hero (ซุปเปอร์ฮีโร่ระดับตำนาน):` เลือด 500 HP, ภูมิต้านทาน 750, ให้รางวัล 300 Bio Points, บินได้
3. **การเชื่อมโยงระบบบอสประจำโซน (Boss Progression Sync):**
   - ปรับปรุง `BossManager.lua` ให้ตรวจสอบสถานะการปลดล็อกโซนก่อนสุ่มเกิดบอส หากโซนของบอสตัวถัดไปยังไม่ปลดล็อก ระบบจะวนกลับไปสุ่มเกิดบอสตัวแรก (Thunderclap) ใน Forest Zone แทน ทำให้การเผชิญหน้าบอสสอดคล้องกับความก้าวหน้าของผู้เล่นอย่างสมบูรณ์แบบ
4. **ระบบแจ้งเตือนและเฉลิมฉลองการปลดล็อก (Progression UI Spectacle):**
   - เชื่อมต่อ Remote Event `ZONE_UNLOCKED` ไปยัง `ClientMain.client.lua` เพื่อแสดง Pop-up เฉลิมฉลองสุดอลังการกลางหน้าจอ (เช่น `🏙️ CITY ZONE UNLOCKED!`) พร้อมเสียงและข้อความเตือนภัย

### แผนงานถัดไป (Next Steps):
- พัฒนาระบบ **Prestige (จุติ)** เพื่อรับ Multipliers และ Plague Tokens และเข้าสู่การขัดเกลางานภาพระดับสูง (Viral Spectacle Polish)

---

## 📅 [2026-05-17] — Phase 3 Beta Complete: Prestige Ascension & Core Loop Replayability
**สถานะปัจจุบัน:** Phase 3 Beta (เสร็จสมบูรณ์ 100%)

### ภารกิจที่ทำสำเร็จ (Completed Work):
1. **ระบบจุติและตัวคูณความก้าวหน้า (Prestige Ascension & Multiplier Engine):**
   - พัฒนาระบบจุติ (`PlayerService.Prestige`) โดยกำหนดเงื่อนไขใช้ 5,000 DNA Points ในการเลื่อนระดับจุติ
   - **Core Loop Reset:** เมื่อจุติสำเร็จ ระบบจะทำการรีเซ็ตค่า Bio Points, DNA Points, TotalBioEarned, LifetimeBioEarned, การปลดล็อกโซนแผนที่ และการอัปเกรดสายพันธุ์ (`MutationService.ResetMutations`) เพื่อท้าทายผู้เล่นให้เริ่มต้นการระบาดใหม่อีกครั้ง
   - **Ascension Rewards:** ผู้เล่นจะได้รับรางวัลตอบแทนถาวร:
     - `✨ Prestige Level:` เลื่อนระดับจุติ +1
     - `⚡ Permanent Multiplier:` เพิ่มตัวคูณ Bio Points +0.5x ต่อระดับ (เช่น P1 = 1.5x, P2 = 2.0x, P3 = 2.5x)
     - `🪙 Plague Tokens:` ได้รับสกุลเงินพิเศษ +1 Plague Token สำหรับใช้แลกเปลี่ยนไอเทมระดับตำนานในอนาคต
2. **ระบบสถาปัตยกรรมเครือข่ายและการเชื่อมต่อ (Network & Service Integration):**
   - เพิ่มการตั้งค่า `Constants.PRESTIGE` และ Remote Events ใหม่ (`REQUEST_PRESTIGE`, `PRESTIGE_CHANGED`) ใน `Constants.lua`
   - ปรับปรุงฟังก์ชัน `PlayerService.AddBioPoints` ให้คำนวณตัวคูณ `PrestigeMultiplier` กับทุกๆ Bio Points ที่ผู้เล่นหาได้อย่างแม่นยำ
3. **ระบบหน้าต่าง UI และแผงควบคุมจุติสุดอลังการ (Ascension UI Spectacle):**
   - **Prestige Button & Panel:** สร้างปุ่มกด **"🔮 PRESTIGE"** ที่มุมขวาล่างของหน้าจอ เมื่อคลิกจะเปิดหน้าต่าง `PrestigePanel` สไตล์ดาร์กแฟนตาซีสีม่วงเรืองแสง
   - **Dynamic Information Display:** แสดงข้อมูลระดับปัจจุบัน, ตัวคูณปัจจุบัน, ตัวคูณถัดไป, แต้ม DNA ที่ต้องการ และรางวัล Plague Tokens แบบเรียลไทม์
   - **Celebration Feedback:** เมื่อกดยืนยันการจุติ ระบบจะส่ง Pop-up อลังการกลางจอ (เช่น `🔮 PRESTIGE 1!`) พร้อมอัปเดตตัวเลขและหลอดเลือดทั้งหมดทันที

### แผนงานถัดไป (Next Steps):
- **ชะลอการเข้าสู่ Phase 4 (Data Persistence & Monetization) ไว้ชั่วคราว:** เพื่อมุ่งเน้นการปรับปรุงระบบเกมเพลย์, สร้างเครื่องมือช่วยทดสอบสำหรับนักพัฒนา (Dev / GM Commands), ขัดเกลาสมดุลเกมเพลย์และ AI, รวมถึงตรวจสอบความถูกต้องของระบบทั้งหมดใน Phase 1-3 ให้มีความสมบูรณ์และสนุกที่สุดก่อนล็อกโครงสร้างข้อมูล

---

## 📅 [2026-05-17] — Phase 3 Beta Polish: Viral Spectacle & Game Feel Overhaul
**สถานะปัจจุบัน:** Phase 3 Beta (ขัดเกลางานภาพและ Game Feel เสร็จสมบูรณ์ 100%)

### ภารกิจที่ทำสำเร็จ (Completed Work):
1. **อนิเมชันเปิดตัวเข้าเกมสุดอลังการ (Cinematic Intro Animation):**
   - พัฒนาฟังก์ชัน `MainHUD.PlayIntroAnimation()` สร้างฉากเปิดตัวเมื่อผู้เล่นเข้าสู่เกม
   - **Test Tube Detonation:** แสดงหลอดทดลองเชื้อไวรัสกลางหน้าจอพร้อมเอฟเฟกต์สั่นสะเทือน ก่อนระเบิดออกเป็นข้อความ **"💥 VIRAL STRAIN RELEASED!!!"**
   - **Dramatic Camera Slam-in:** สคริปต์ควบคุมกล้องให้ซูมเข้าหาตัวละครผู้เล่นจากมุมสูงอย่างรวดเร็ว (Slam-in) พร้อมเอฟเฟกต์ Screen Shake สั่นสะเทือนทั่วทั้งหน้าจอ
2. **ระบบหยุดเวลาเพื่อความสะใจ (60ms Hit Freeze / Hit Stop):**
   - เพิ่มระบบ Hit Freeze ใน `ClientMain.client.lua` ทันทีที่เกิดการแพร่ระบาด (`INFECTION_SPREAD`)
   - ระบบจะทำการหยุดความเร็วอนิเมชันของตัวละคร (`track:AdjustSpeed(0)`) เป็นเวลา 60 มิลลิวินาที ก่อนฟื้นคืนความเร็วปกติ สร้างความรู้สึกกระแทกกระทั้น (Impact Juice) ระดับพรีเมียม
3. **ระบบนับคอมโบและตัวหนังสือกระแทกจอ (Dynamic Combo Slam UI):**
   - พัฒนาระบบติดตามคอมโบต่อเนื่องภายใน 4 วินาที หากทำคอมโบต่อเนื่องตั้งแต่ 2 ครั้งขึ้นไป ระบบจะเรียกใช้ `MainHUD.ShowCombo(comboCount)`
   - **Slamming Typography:** ตัวอักษรคอมโบขนาดใหญ่ (เช่น `🔥 COMBO x10!!!`) จะเด้งกระแทกกลางหน้าจอพร้อมเปลี่ยนสีตามระดับความโหด (Yellow ➡️ Orange ➡️ Red ➡️ Purple Glow)
4. **บรรยากาศสปอร์พิษและสีสันแวดล้อม (Airborne Spores & Ambient Color Cycling):**
   - **Ambient Toxic Spores:** ติดตั้งระบบ Particle สปอร์พิษลอยวนรอบตัวละครผู้เล่นตลอดเวลา สร้างบรรยากาศหมอกพิษและฝุ่นละอองชีวภาพ
   - **UI Color Cycling:** ใช้ `RunService.RenderStepped` ขับเคลื่อนแผงควบคุมหลัก (`MainPanel`) ให้เปลี่ยนสีเส้นขอบและเงาสะท้อน (Glow) วนลูปไปตามเฉดสี Toxic Green, Bio Blue และ Plague Purple อย่างนุ่มนวลตลอดเวลา

### แผนงานถัดไป (Next Steps):
- **ชะลอการเข้าสู่ Phase 4 (Data Persistence & Monetization) ไว้ชั่วคราว:** เพื่อมุ่งเน้นการปรับปรุงระบบเกมเพลย์, สร้างเครื่องมือช่วยทดสอบสำหรับนักพัฒนา (Dev / GM Commands), ขัดเกลาสมดุลเกมเพลย์และ AI, รวมถึงตรวจสอบความถูกต้องของระบบทั้งหมดใน Phase 1-3 ให้มีความสมบูรณ์และสนุกที่สุดก่อนล็อกโครงสร้างข้อมูล
