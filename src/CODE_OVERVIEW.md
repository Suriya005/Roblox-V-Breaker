# Roblox V-Breaker: Source Code Overview (src)

เอกสารนี้อธิบายโค้ดแบบคร่าวๆ ของโฟลเดอร์ `src` เพื่อให้เห็นภาพรวมระบบ, จุดเริ่มต้นของแต่ละฝั่ง, และหน้าที่ของแต่ละไฟล์

## โครงสร้างภาพรวม

- `src/server` = ระบบฝั่งเซิร์ฟเวอร์ (authoritative game logic)
- `src/client` = ระบบฝั่งผู้เล่น/การแสดงผล (input, UI, visual effects)
- `src/shared` = ค่าคงที่และโค้ดที่ใช้ร่วมกันระหว่าง server/client

---

## 1) Shared Layer (`src/shared`)

### `constants/Constants.lua`
หน้าที่:
- รวมค่าคงที่หลักของเกม
- กำหนดค่าพื้นฐานระบบ Infection (radius/chance/tick/cooldown)
- กำหนดสเตตัส NPC แต่ละ tier (Animal/Human/Military/Supe/Boss)
- ประกาศชื่อ RemoteEvent ทั้งหมดใน `Constants.REMOTES`
- กำหนดค่าระบบ Prestige

ผลลัพธ์:
- เป็น single source of truth ของชื่อรีโมตและค่าบาลานซ์หลัก

### `constants/MutationTree.lua`
หน้าที่:
- กำหนด mutation ทั้งหมดของเกม (Transmission/Symptoms/Abilities)
- ระบุเงื่อนไขการปลดล็อก (`Req`), ราคาซื้อ, ประเภทผล (`EffectType`), และค่าผล (`EffectValue`)

ผลลัพธ์:
- เป็น data-driven config สำหรับร้าน mutation และการคำนวณบัฟของผู้เล่น

### `network/RemoteManager.lua`
หน้าที่:
- สร้าง/เข้าถึง RemoteEvents แบบรวมศูนย์
- ฝั่ง server ใช้ `Init()` เพื่อสร้างรีโมตจาก `Constants.REMOTES`
- มี helper สำหรับ `FireClient`, `FireAllClients`, `FireServer`, `OnServerEvent`, `OnClientEvent`

ผลลัพธ์:
- ลดการกระจายการจัดการ RemoteEvent และลดโอกาสสะกดชื่อผิด

---

## 2) Server Layer (`src/server`)

### `ServerMain.server.lua` (Entry Point)
ลำดับเริ่มต้นหลัก:
1. `RemoteManager.Init()`
2. `PlayerService.Init()`
3. `InfectionEngine.Init()`
4. `NPCSpawner.Init()`
5. `MutationService.Init()`
6. `GovernmentAI.Init()`
7. `BossManager.Init()`

หน้าที่:
- จุดรวมการ bootstrap ระบบฝั่ง server ทั้งหมด

### `services/PlayerService.lua`
หน้าที่:
- เก็บ state ผู้เล่นในหน่วยความจำ (`playerData`) เช่น Bio/DNA, zone unlock, prestige
- ให้ API เพิ่ม/หักแต้ม (`AddBioPoints`, `AddDnaPoints`, `Deduct*`)
- แปลง Bio -> DNA ตาม threshold
- ปลดล็อกโซนตาม `LifetimeBioEarned`
- จัดการคำสั่ง Prestige และรีเซ็ตความคืบหน้า

สังเกต:
- ตอนนี้เป็นข้อมูล in-memory ยังไม่ต่อ DataStore

### `services/MutationService.lua`
หน้าที่:
- เก็บ mutation ที่ผู้เล่นปลดล็อก (`playerMutations`)
- ตรวจสอบและดำเนินการซื้อ mutation (`BuyMutation`)
- ส่งสถานะไป client (`SYNC_MUTATIONS`, `MUTATION_UNLOCKED`)
- ให้ helper สำหรับระบบอื่น เช่น
  - `GetSpreadRadius()`
  - `GetSpreadChance()`
  - `GetTickRate()`
  - `GetBossDPS()`
  - `GetCriticalInfectChance()`

### `services/InfectionEngine.lua`
หน้าที่:
- รับคำสั่งติดเชื้อ/โจมตีจากผู้เล่นผ่าน `REQUEST_INFECT`
- กรณีเป้าหมายยังไม่ติดเชื้อ: เรียก `InfectNPC`
- กรณีติดเชื้ออยู่แล้ว: คิด melee damage
- ลูปหลัก (`StartLoop`) ทำงานเป็นระยะเพื่อ:
  - ลดเลือด NPC ติดเชื้อ
  - กระจายเชื้อไปยัง NPC ใกล้เคียงตามระยะและโอกาส
  - อัปเดตป้ายสถานะ/HP bar
  - แจก Bio/DNA และทำลาย NPC เมื่อตาย

### `services/NPCSpawner.lua`
หน้าที่:
- สร้างโซน spawn หลักของแผนที่ (Forest/City/Military/Vought)
- คุมจำนวน spawn ต่อ tier/โซน
- สุ่มชนิด NPC ตามน้ำหนัก (`SpawnWeight`)
- สร้างโมเดลพร้อม attributes และ Billboard UI (ชื่อ/สถานะ/HP)
- รัน AI loop ของแต่ละประเภท (Animal/Human/Military/Supe)

### `services/GovernmentAI.lua`
หน้าที่:
- คำนวณสถานะภัยคุกคามรายโซน (Threat Level)
- เพิ่มความคืบหน้าวิจัยวัคซีนตามระดับภัย
- เมื่อครบ 100% เรียก Doctor ลงพื้นที่เพื่อรักษา NPC
- ซิงค์ Threat/Vaccine HUD ให้ผู้เล่นตามโซนที่ยืนอยู่
- ตรวจ mutation ต้านวัคซีนบางส่วน (`DRUG_RESIST_1`, `GENETIC_HARD`)

### `services/BossManager.lua`
หน้าที่:
- คุมการเกิดบอสประจำโซน (1 ตัวต่อโซน)
- สุ่มเกิดตามรอบเวลา ถ้าโซนถูกปลดล็อกแล้ว
- ซิงค์ข้อมูลบอสกับผู้เล่นในโซนนั้น (spawn/health/defeated)
- รัน AI เดินลาดตระเวน + เอฟเฟกต์สกิลบอส

---

## 3) Client Layer (`src/client`)

### `ClientMain.client.lua` (Entry Point)
หน้าที่หลัก:
- โหลด modules ฝั่ง client: `MainHUD`, `MutationShop`, `SettingsPanel`
- subscribe RemoteEvents เพื่ออัปเดต UI/feedback
- จัดการระบบ input ผู้เล่น:
  - ต่อย/ตี (active melee hitbox)
  - วิ่ง (Shift sprint)
  - แดช (Q warp dash)
- จัดการ visual/game-feel:
  - particle, popup, combo, hit freeze, intro animation
- จัดการ logic ฝั่ง client สำหรับบอสและเลเซอร์ปลดโซน

### `ui/MainHUD.lua`
หน้าที่:
- สร้าง HUD หลักทั้งหมด
  - Bio/DNA
  - progress bar
  - threat/vaccine panel
  - boss panel
  - prestige panel
- มี method อัปเดตข้อมูลและแสดง feedback เช่น
  - `UpdateBio`, `UpdateDna`
  - `ShowNotification`, `ShowPopup`, `ShowCombo`
  - `UpdateThreatLevel`, `UpdateVaccineProgress`
  - `ShowBossBar`, `UpdateBossHealth`, `HideBossBar`
  - `UpdatePrestige`

### `ui/MutationShop.lua`
หน้าที่:
- สร้างหน้าต่างร้าน mutation
- แบ่งแท็บตาม category
- สร้างการ์ด mutation จาก `MutationTree`
- ส่งคำสั่งซื้อไป server (`BUY_MUTATION`)
- รับ sync สถานะปลดล็อกจาก server เพื่ออัปเดตปุ่มการ์ด

### `ui/SettingsPanel.lua`
หน้าที่:
- สร้าง panel ตั้งค่า local ของผู้เล่น
- รองรับ toggle: SFX, Particles, ScreenShake, Popups
- เป็นตัวกำหนดว่า client จะเปิด/ปิด effect ต่างๆ ใน runtime

---

## 4) Data Flow สำคัญ

### A) วงจรติดเชื้อ
1. ผู้เล่นโจมตีเป้าหมาย -> client ส่ง `REQUEST_INFECT`
2. server `InfectionEngine` ตัดสินใจติดเชื้อหรือสร้างดาเมจ
3. เมื่อสำเร็จ ส่ง event กลับ client (`INFECTION_SPREAD`, `SHOW_POPUP`)
4. loop ฝั่ง server ค่อยๆ กระจายเชื้อ/ลดเลือด/แจกแต้ม

### B) วงจรแต้มและ progression
1. ฆ่าหรือแพร่เชื้อสำเร็จ -> ได้ Bio
2. Bio สะสมถึง threshold -> ได้ DNA เพิ่ม
3. สะสม LifetimeBio -> ปลดล็อกโซน (City/Military/Vought)
4. client รับ event แล้วเปิดทางเลเซอร์ + แจ้งเตือน

### C) วงจร mutation
1. client กดซื้อใน `MutationShop`
2. server ตรวจ prerequisite + หักแต้ม
3. ปลดล็อกสำเร็จ -> ส่ง `MUTATION_UNLOCKED`/`SYNC_MUTATIONS`
4. mutation มีผลต่อ infection ผ่าน helper ใน `MutationService`

### D) วงจรรัฐบาลและวัคซีน
1. `GovernmentAI` ประเมิน infected count ต่อโซน
2. เพิ่ม Threat Level และ Vaccine Progress
3. ครบเงื่อนไข -> spawn Doctor มารักษา NPC
4. HUD ของผู้เล่นอัปเดตตามโซนปัจจุบัน

---

## 5) จุดที่ควรรู้สำหรับนักพัฒนาที่เข้ามาต่อ

- ระบบนี้เป็น architecture แบบ service-oriented ชัดเจน (server services + client ui/controllers)
- ค่าบาลานซ์เกือบทั้งหมดถูกรวมใน `Constants.lua` และ `MutationTree.lua`
- การสื่อสาร client-server รวมศูนย์ผ่าน `RemoteManager`
- ปัจจุบันข้อมูลผู้เล่นอยู่ในหน่วยความจำ ยังไม่ persistence (ยังไม่มี DataStore integration)
- การปลดล็อกโซน, บอส, รัฐบาล, mutation เชื่อมโยงกันผ่าน attribute และ event ค่อนข้างแน่น

---

## 6) ไฟล์เริ่มอ่านแนะนำ (Onboarding Quick Path)

1. `src/server/ServerMain.server.lua`
2. `src/shared/constants/Constants.lua`
3. `src/shared/network/RemoteManager.lua`
4. `src/server/services/PlayerService.lua`
5. `src/server/services/InfectionEngine.lua`
6. `src/client/ClientMain.client.lua`
7. `src/client/ui/MainHUD.lua`

อ่านตามนี้จะเห็นภาพระบบครบเร็วที่สุด
