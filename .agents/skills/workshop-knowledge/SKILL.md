---
name: workshop-knowledge
description: Instructs the agent to always search the global Knowledge Base before creating new workshop systems, and encourages saving new knowledge when a system is completed.
---

# Workshop Knowledge Skill

## Instructions

Whenever the user asks you to build a new system, mechanic, or workshop:

1. **Pre-Flight Check (Knowledge Retrieval):**
   - You MUST first check if there is any existing documentation in the global knowledge base located at `C:\Users\Javis\OneDrive\Documents\GitHub\Roblox-Shared-Workspace\_Knowledge`.
   - Read the `README.md` in that folder to see if there is an index of lessons that might match the user's request.
   - If a relevant lesson is found, read it carefully and apply the architectural patterns and shared modules mentioned there.

2. **Shared Modules Check:**
   - Look inside `C:\Users\Javis\OneDrive\Documents\GitHub\Roblox-Shared-Workspace\SharedModules` to see if there is an existing reusable `ModuleScript` that solves part of the problem.
   - If the user's project uses Rojo, ensure they have mapped the `SharedModules` folder in their `default.project.json` before trying to write duplicate code.

3. **Post-Flight (Knowledge Storage):**
   - After successfully completing a new system or workshop, ask the user if they would like you to document the learnings.
   - If they agree, use `TEMPLATE_LESSON.md` to create a new markdown file in the `_Knowledge` folder.
   - Extract any universally useful code into a `ModuleScript` and place it in the `SharedModules` folder.
