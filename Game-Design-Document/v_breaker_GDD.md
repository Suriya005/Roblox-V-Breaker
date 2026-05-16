# 🦠 Game Design Document — V-Breaker
### Inspired by *The Boys* | Roblox Game Project
**Version:** 1.0  
**Date:** 2026-05-16  
**Engine:** Roblox Studio (Luau)

---

## 1. Overview

### 1.1 Concept
ผู้เล่นรับบทเป็น **นักวิทยาศาสตร์ลับ** ที่สร้างและวิวัฒนาการไวรัสเพื่อกำจัด Superhero ที่มีพลัง Compound V โดยเริ่มจากติดเชื้อในสัตว์ก่อน จากนั้นค่อยๆ evolve ไวรัสให้แข็งแกร่งพอที่จะโจมตีมนุษย์และ Supes ได้ในที่สุด

### 1.2 Genre
Idle / Incremental Simulator + Strategy

### 1.3 Platform
Roblox (PC & Mobile)

### 1.4 Target Audience
ผู้เล่น Roblox อายุ 13+ ที่ชื่นชอบ strategy และ incremental games

### 1.5 Inspiration
- *The Boys* (Amazon Prime) — แนวคิดไวรัสกำจัด Supe
- *Plague Inc.* — mechanics การแพร่เชื้อและ mutation
- *Pet Simulator X* — ระบบ Prestige และ DNA currency

---

## 2. Core Gameplay Loop

```
เริ่มเกม
   │
   ▼
ปล่อยไวรัสในโซนสัตว์
   │
   ▼
สะสม Bio Points จาก NPC ที่ติดเชื้อ
   │
   ▼
ใช้ Bio Points → ซื้อ Mutation ใน DNA Shop
   │
   ▼
ไวรัสแรงขึ้น → ติดเชื้อ Tier สูงขึ้น
   │
   ▼
เอาชนะ Boss แต่ละ Tier
   │
   ▼
Prestige → รับ Bonus Multiplier → เริ่มใหม่แบบแข็งแกร่งกว่าเดิม
```

---

## 3. Progression System

### 3.1 Tier ของ Host

| Tier | เป้าหมาย | ภูมิคุ้มกัน | Bio Points ที่ได้ |
|------|----------|------------|-----------------|
| 1 | สัตว์ (หนู, นก, ลิง, หมู) | ต่ำมาก | x1 |
| 2 | มนุษย์ธรรมดา | ปานกลาง | x5 |
| 3 | Supes (Compound V) | สูงมาก | x50 |
| 4 | Boss (Homelander Class) | สูงสุด | x500 |

> **หมายเหตุ:** ต้อง unlock Mutation **"Compound V Breaker"** ก่อนถึงจะโจมตี Tier 3 ได้

### 3.2 Currency

| Currency | วิธีได้มา | ใช้ทำอะไร |
|----------|----------|----------|
| 🧫 Bio Points | ติดเชื้อ NPC | ซื้อ Mutation พื้นฐาน |
| 🧬 DNA Points | Bio Points สะสมถึงเกณฑ์ | ซื้อ Mutation พิเศษ |
| ☣️ Plague Tokens | เอาชนะ Boss | ซื้อ Prestige Upgrade |

---

## 4. Mutation System

### 4.1 Mutation Tree (ต้อง unlock ตามลำดับ)

```
[Airborne] ──────────────────────────────┐
                                          ▼
[Hemorrhagic] ──► [Drug Resistant] ──► [Compound V Breaker] ──► [Neuro-Attack]
                                          ▲
[Dormant] ───────────────────────────────┘
```

### 4.2 รายการ Mutation

| Mutation | ผล | DNA Cost | Prerequisite |
|----------|-----|----------|--------------|
| ⚡ Airborne | แพร่ผ่านอากาศ radius 20 studs | 50 | — |
| 🔥 Hemorrhagic | DoT +50% แต่ host ตายเร็วขึ้น 30% | 60 | — |
| 🛡️ Drug Resistant | ลดประสิทธิภาพวัคซีน NPC 50% | 80 | Hemorrhagic |
| 🐛 Dormant | ซ่อนอาการ ทำให้ Government detect ช้าลง 50% | 120 | Airborne |
| 🧪 Compound V Breaker | Unlock การติดเชื้อ Supe (Tier 3) | 200 | Drug Resistant + Dormant |
| 👁️ Neuro-Attack | Supe ใช้พลังไม่ได้ชั่วคราว (5 วินาที) | 300 | Compound V Breaker |
| 💀 Cytokine Storm | ดาเมจ AoE โจมตีพร้อมกันทุก host ในพื้นที่ | 500 | Neuro-Attack |

---

## 5. NPC & AI System

### 5.1 NPC ประเภทสัตว์ (Tier 1)

- **Rat** — เคลื่อนที่เร็ว, ภูมิคุ้มกันต่ำสุด, spawn จำนวนมาก
- **Bird** — บินข้ามโซน ช่วยแพร่เชื้อข้ามพื้นที่
- **Pig** — ภูมิคุ้มกันสูงกว่า rat แต่ให้ Bio Points มากกว่า
- **Monkey** — ภูมิคุ้มกันปานกลาง, ฉลาดกว่า (หนีเมื่อเห็นการติดเชื้อ)

### 5.2 NPC มนุษย์ (Tier 2)

- มี **ImmuneStrength** ที่คำนวณแบบ random ในช่วง 40–80
- เมื่อติดเชื้อจะ "รายงาน" ต่อ GovernmentAI
- บาง NPC คือ **Doctor** จะพยายามรักษาคนรอบข้าง (ลด spread)

### 5.3 Supes (Tier 3)

- **ImmuneStrength** สูงมาก (150–300)
- ต้องมี Mutation "Compound V Breaker" ก่อนถึงจะติดเชื้อได้
- มีพลังพิเศษ เช่น บินหนี, ยิงเลเซอร์ใส่ไวรัส (ลด spread rate)
- ใช้ "Neuro-Attack" เพื่อปิดพลังชั่วคราว

---

## 6. Government AI System

GovernmentAI จะ monitor infection rate และ escalate ตาม **Threat Level**

| Threat Level | เงื่อนไข | รัฐบาลทำอะไร |
|-------------|---------|------------|
| 1 — Normal | infected < 5% | ไม่มีอะไร |
| 2 — Alert | infected 5–15% | ประกาศเตือน, NPC เริ่มระวังตัว |
| 3 — Lockdown | infected 15–35% | NPC อยู่นิ่ง ติดยากขึ้น 30% |
| 4 — Vaccine | infected 35–60% | วัคซีนถูกพัฒนา ลด spread rate 50% |
| 5 — Supe Deploy | infected > 60% | **ส่ง Supes มาโจมตีผู้เล่นโดยตรง!** |

> **เคล็ดลับ:** ใช้ Mutation "Dormant" เพื่อซ่อนการแพร่เชื้อและชะลอ Threat Level

---

## 7. Boss System

### 7.1 Boss Lineup

| Boss | Tier | HP | จุดอ่อน | รางวัล |
|------|------|-----|---------|-------|
| ⚡ Thunderclap | 3 | 500,000 | Neuro-Attack | DNA x200, Plague Token x1 |
| 🔥 Inferno | 3 | 1,200,000 | Dormant + Airborne combo | DNA x500, Plague Token x3 |
| 🌊 Vortex | 3 | 3,000,000 | Compound V Breaker required | DNA x1,000, Plague Token x5 |
| ☀️ **SUPREME** | 4 | 50,000,000 | ต้องมี Mutation ครบทุกสาย | Prestige Unlock, Title พิเศษ |

### 7.2 Boss Phase System

**SUPREME** มี 3 Phase:
- **Phase 1 (HP 100–60%):** เคลื่อนที่ปกติ, ต้านทาน mutation บางตัว
- **Phase 2 (HP 60–30%):** ออก Laser Ray ล้างไวรัสในพื้นที่, immune boost +50%
- **Phase 3 (HP 30–0%):** เรียก Supe เสริม 3 ตัว, spread rate ลดลง 70%

---

## 8. Map Design

### 8.1 โซนในแผนที่

```
┌──────────────────────────────────────────┐
│  🌲 Forest Zone    │  🏙️ City Zone        │
│  (Tier 1 สัตว์)    │  (Tier 2 มนุษย์)    │
├────────────────────┼─────────────────────┤
│  🏭 Military Base  │  🏢 Vought HQ        │
│  (Tier 3 Supes)   │  (Tier 4 Boss)      │
└──────────────────────────────────────────┘
```

### 8.2 Visual Style (ไม่ต้องมี Model ซับซ้อน)

- ทุกโซนใช้ **Part ธรรมดา** + สีสันแทน mesh model
- NPC ติดเชื้อ → Part เปลี่ยนสีเป็น **สีเขียว/ดำ**
- Spread effect = **ParticleEmitter** สีเขียวลอยออกจาก NPC
- Boss = Part ซ้อนกัน + **BillboardGui** แสดงชื่อและ HP bar
- Map unlock ทีละโซนเมื่อ clear Tier ก่อนหน้า

---

## 9. Script Architecture

### 9.1 โครงสร้าง Script

```
ServerScriptService/
├── Main.server.lua          -- entry point
├── InfectionEngine.lua      -- ModuleScript: ระบบแพร่เชื้อ
├── GovernmentAI.lua         -- ModuleScript: AI รัฐบาล
├── BossManager.lua          -- ModuleScript: จัดการ Boss
├── NPCSpawner.lua           -- ModuleScript: spawn NPC
└── DataManager.lua          -- ModuleScript: save/load ด้วย DataStore

ReplicatedStorage/
├── MutationTree.lua         -- ModuleScript: ข้อมูล Mutation ทั้งหมด
├── PlayerProgress.lua       -- ModuleScript: track progress ผู้เล่น
└── Config.lua               -- ModuleScript: ค่า config ทั้งหมด (balance)

StarterGui/
├── MainHUD/                 -- Bio Points, DNA Points แสดงผล
├── MutationShop/            -- UI ซื้อ Mutation
├── BossHealthBar/           -- HP bar Boss
└── ThreatLevelDisplay/      -- แสดง Government Threat Level
```

### 9.2 Core Module Responsibilities

**`InfectionEngine`**
- วนหา NPC ทุกตัวใน workspace ทุก tick
- เช็ค proximity กับ infected NPC
- roll spread chance โดยใช้ `ImmuneStrength` ของเป้าหมาย
- apply Mutation modifiers (Airborne radius, Hemorrhagic DoT ฯลฯ)

**`GovernmentAI`**
- นับ infected NPC ทั่วโลกทุก 5 วินาที
- คำนวณ infection % และเปลี่ยน Threat Level
- trigger lockdown, vaccine, และ Supe deploy ตาม Level

**`MutationTree`**
- เก็บ node data ทุก Mutation (cost, effect, prerequisite)
- validate การซื้อ (มี prerequisite ครบไหม, DNA พอไหม)
- apply effect ไปยัง InfectionEngine config

**`BossManager`**
- spawn Boss เมื่อ Tier ผ่าน
- จัดการ Phase transition
- คำนวณ damage ตาม Mutation ที่ผู้เล่นมี

**`DataManager`**
- ใช้ ProfileService หรือ DataStore2
- save: Bio Points, DNA Points, Plague Tokens, Mutation ที่ unlock, Prestige level
- auto-save ทุก 30 วินาที + save เมื่อ player ออกจากเกม

---

## 10. Prestige System

หลังจาก kill SUPREME (Final Boss):
- Reset: Bio Points, DNA Points, Mutation ทั้งหมด
- **รับ:** Prestige Level +1 → Bio Point multiplier ถาวร (+25% ต่อ level)
- Unlock: สีไวรัสพิเศษ, title บน leaderboard, Mutation พิเศษที่ซื้อได้ด้วย Plague Token

---

## 11. Monetization (Robux)

| รายการ | ราคา (Robux) | หมายเหตุ |
|--------|-------------|---------|
| 2x Bio Points Gamepass | 199 | permanent multiplier |
| Auto-Spread Bot | 299 | แพร่เชื้ออัตโนมัติโดยไม่ต้องคลิก |
| Exclusive Virus Skin | 99 | cosmetic เท่านั้น |
| DNA Pack (500 DNA) | 149 | one-time purchase |

> **หลักการ:** ไม่มี Pay-to-Win — Robux ซื้อได้แค่ cosmetic และ QoL ไม่ได้ซื้อ power

---

## 12. Development Milestones

| Milestone | งาน | ประมาณเวลา |
|-----------|-----|-----------|
| **M1 — Core Loop** | InfectionEngine + NPC Tier 1 + Bio Points | 1–2 สัปดาห์ |
| **M2 — Mutation** | MutationTree + DNA Shop UI | 1 สัปดาห์ |
| **M3 — Government** | GovernmentAI + Threat Level system | 1 สัปดาห์ |
| **M4 — Tier 2–3** | Human & Supe NPC + Compound V Breaker | 1–2 สัปดาห์ |
| **M5 — Boss** | BossManager + Boss 1–4 + Phase system | 2 สัปดาห์ |
| **M6 — Polish** | DataStore, Prestige, UI สวยงาม, Balance | 1–2 สัปดาห์ |

---

## 13. Technical Notes

- **Luau Strict Mode** — เปิดใช้ `--!strict` ทุก ModuleScript
- **Remote Events** — ใช้ RemoteEvent/RemoteFunction สำหรับ Client↔Server
- **Anti-Exploit** — ตรวจสอบ Bio Points และ Mutation purchase บน Server เสมอ
- **Performance** — ใช้ `task.wait()` แทน `wait()`, cull NPC ที่ไกลเกิน 200 studs
- **Data Safety** — ใช้ `pcall()` ครอบทุก DataStore call

---

*GDD Version 1.0 — สร้างโดย Claude สำหรับโปรเจกต์ V-Breaker*
