# 📋 รายการงาน (Task List) — V-Breaker

> **สถานะโครงการ (Project Status):** Phase 1 - Prototype (กำลังเริ่มต้นพัฒนา Core Loop)

---

## 🏁 Phase 0: Project Setup & Design (เสร็จสิ้น)
- [x] ออกแบบโครงสร้างและวิสัยทัศน์ของเกม (Main GDD)
- [x] กำหนดทิศทางงานภาพและ Game Feel (Viral Spectacle & Juice)
- [x] ตั้งชื่อโปรเจกต์เป็น **V-Breaker** และอัปเดตไฟล์โครงสร้าง (`default.project.json`)

---

## 🛠️ Phase 1: Prototype (Core Loop)
- [x] **ระบบแพร่เชื้อพื้นฐาน (Infection Engine):**
  - [x] สร้างสคริปต์คำนวณการติดเชื้อและระยะการแพร่กระจาย (`InfectionEngine.lua`)
  - [x] จัดการระบบนับและสะสม Bio Points เมื่อ NPC ติดเชื้อ
- [x] **ระบบ Spawn NPC (Tier 1 - สัตว์):**
  - [x] สร้างระบบสุ่มเกิดหนู นก และลิง (`NPCSpawner.lua`)
  - [x] กำหนด AI เดินสุ่มและพฤติกรรมของสัตว์
- [x] **ระบบ UI พื้นฐาน (Main HUD):**
  - [x] สร้างหน้าต่างแสดงผลจำนวน Bio Points และ DNA Points
- [x] **งานภาพและ Game Feel (Visual & Juice):**
  - [x] ใส่ Particle Emitter สีเขียวสะท้อนแสงเวลาติดเชื้อ
  - [x] ติดตั้งระบบ Screen Shake เบื้องต้นเมื่อเกิดเหตุการณ์สำคัญ

---

## 🧬 Phase 2: Alpha (Mutation & AI)
- [ ] **ระบบกลายพันธุ์ (Mutation Tree & Shop):**
  - [ ] สร้างข้อมูลสายต้นไม้ Mutation (`MutationTree.lua`)
  - [ ] ทำหน้าต่าง UI สำหรับใช้ Bio/DNA Points ซื้ออัปเกรด (เช่น Airborne, Drug Resistant)
- [ ] **ระบบ AI รัฐบาล (Government Threat Level):**
  - [ ] สคริปต์คำนวณสัดส่วนการติดเชื้อและยกระดับ Threat Level (`GovernmentAI.lua`)
  - [ ] เพิ่มสถานะ Lockdown และการพัฒนา Vaccine
- [ ] **NPC มนุษย์ (Tier 2):**
  - [ ] สร้าง NPC มนุษย์พร้อมระบบแสดงอารมณ์/รีแอคชั่นเมื่อติดเชื้อ (ตกใจ, วิ่งหนี)

---

## ⚔️ Phase 3: Beta (Bosses & Game Feel Polish)
- [ ] **ระบบบอสประจำโซน (Boss Manager):**
  - [ ] สร้างระบบบอส (เช่น Thunderclap, Inferno, Vortex, SUPREME)
  - [ ] ทำหลอดเลือดบอส (Boss Health Bar) และระบบ Phase
- [ ] **ระบบปลดล็อกโซนแผนที่ (Map Progression):**
  - [ ] Forest Zone ➡️ City Zone ➡️ Military Base ➡️ Vought HQ
- [ ] **ระบบ Prestige (จุติ):**
  - [ ] รีเซ็ตความคืบหน้าเพื่อรับ Multiplier ถาวรและ Plague Tokens
- [ ] **ขัดเกลางานภาพระดับสูง (Viral Spectacle Polish):**
  - [ ] อนิเมชันเปิดตัวเข้าเกม (หลอดทดลองระเบิด + ตัวละคร Slam-in)
  - [ ] ระบบ Hit Freeze 60ms เพื่อความสะใจ
  - [ ] ตัวหนังสือ Combo `x5`, `x10`, `x50` เด้งกระแทกหน้าจอ
  - [ ] สปอร์และฝุ่นพิษลอยในอากาศ + Color Cycling พื้นหลัง

---

## 🚀 Phase 4: Launch (เปิดตัว)
- [ ] **ระบบบันทึกข้อมูล (Data Persistence):**
  - [ ] เชื่อมต่อ DataStore / ProfileService (`DataManager.lua`)
- [ ] **ระบบสร้างรายได้ (Monetization):**
  - [ ] Gamepass 2x Bio Points และ Auto-Spread Bot
  - [ ] Developer Products (DNA Packs) และระบบสกินไวรัส (Cosmetics)
- [ ] **เสียงและดนตรีประกอบ (Audio & BGM):**
  - [ ] เสียงเอฟเฟกต์การระเบิดของเชื้อ, เสียง Pop-up และ BGM ประจำโซน

---
*อัปเดตล่าสุด: 2026-05-16*
