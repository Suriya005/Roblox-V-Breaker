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
- [x] **ระบบกลายพันธุ์ (Mutation Tree & Shop):**
  - [x] สร้างข้อมูลสายต้นไม้ Mutation (`MutationTree.lua`)
  - [x] ทำหน้าต่าง UI สำหรับใช้ Bio/DNA Points ซื้ออัปเกรด (เช่น Airborne, Drug Resistant)
- [x] **ระบบ AI รัฐบาล (Government Threat Level):**
  - [x] สคริปต์คำนวณสัดส่วนการติดเชื้อและยกระดับ Threat Level (`GovernmentAI.lua`)
  - [x] เพิ่มสถานะ Lockdown และการพัฒนา Vaccine
- [x] **NPC มนุษย์ (Tier 2):**
  - [x] สร้าง NPC มนุษย์พร้อมระบบแสดงอารมณ์/รีแอคชั่นเมื่อติดเชื้อ (ตกใจ, วิ่งหนี)

---

## ⚔️ Phase 3: Beta (Bosses & Game Feel Polish)
- [x] **ระบบบอสประจำโซน (Boss Manager):**
  - [x] สร้างระบบบอส (เช่น Thunderclap, Inferno, Vortex, SUPREME)
  - [x] ทำหลอดเลือดบอส (Boss Health Bar) และระบบ Phase
- [x] **ระบบปลดล็อกโซนแผนที่ (Map Progression):**
  - [x] Forest Zone ➡️ City Zone ➡️ Military Base ➡️ Vought HQ
- [x] **ระบบ Prestige (จุติ):**
  - [x] รีเซ็ตความคืบหน้าเพื่อรับ Multiplier ถาวรและ Plague Tokens
- [x] **ขัดเกลางานภาพระดับสูง (Viral Spectacle Polish):**
  - [x] อนิเมชันเปิดตัวเข้าเกม (หลอดทดลองระเบิด + ตัวละคร Slam-in)
  - [x] ระบบ Hit Freeze 60ms เพื่อความสะใจ
  - [x] ตัวหนังสือ Combo `x5`, `x10`, `x50` เด้งกระแทกหน้าจอ
  - [x] สปอร์และฝุ่นพิษลอยในอากาศ + Color Cycling พื้นหลัง

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
