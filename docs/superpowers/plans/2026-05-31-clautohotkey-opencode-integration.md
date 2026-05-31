# ClautoHotkey -> opencode 集成 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate ClautoHotkey's AHK v2 knowledge and AI agents into opencode workflow by enhancing AGENTS.md and creating `.opencode/agents/` subagent templates.

**Architecture:** One enhanced AGENTS.md (append ~250 lines of AHK v2 standards) + 6 subagent prompt templates in `.opencode/agents/`. ClautoHotkey/ kept as-is as reference library. Zero changes to `src/`.

**Files created:** 6 new files in `.opencode/agents/`
**Files modified:** 1 file (`./AGENTS.md`)

---

### Task 1: Enhance AGENTS.md with AHK v2 Development Standards

**Files:**
- Modify: `./AGENTS.md:130` (append after last line)

- [ ] **Step 1: Append AHK v2 Development Standards section to AGENTS.md**

Current AGENTS.md ends at line 130 (Commit Messages section). Append the following content after it:

```markdown

## AHK v2 Development Standards (from ClautoHotkey)

### Core Engineering Principles

| Principle | Rule |
|-----------|------|
| **KISS & YAGNI** | Simplest solution that works. Never build for hypothetical needs. |
| **Rule of Three** | Introduce abstractions only after logic repeats in three distinct locations. Never add speculatively. |
| **Two Hats Rule** | Structural refactoring and feature additions belong in separate responses. Never combine. |
| **Boy Scout Rule** | Clean only the immediate context being edited — never rewrite an entire class when touching one method. |
| **Right-Sizing** | Match architectural complexity to project scale. Do not force MVC on scripts < 50 lines. |

### AHK v2 Critical Rules (Beyond Basics)

The following rules are **strictly enforced** — violations cause runtime errors or silent failures:

| # | Rule | Correct Pattern | Wrong Pattern |
|---|------|----------------|---------------|
| 1 | No `new` keyword | `obj := ClassName()` | `obj := new ClassName()` → parse error |
| 2 | `.Bind(this)` for callbacks | `ctrl.OnEvent("Click", this.Handler.Bind(this))` | `ctrl.OnEvent("Click", this.Handler)` → wrong `this` |
| 3 | `Map()` for key-value data | `state := Map("x", 0, "y", 0)` | `state := {x: 0, y: 0}` — no `.Has()`/`.Delete()` |
| 4 | `:=` not `=` for assignment | `x := 5 + 2` | `x = 5 + 2` → case-insensitive string comparison |
| 5 | `super.__New(args*)` | `super.__New(make, model)` | `super(args*)` → base constructor never runs |
| 6 | `#HotIf` not `#If` | `#HotIf WinActive("Title")` | `#If` silently ignored in v2 |
| 7 | Fat arrows single-line only | `(*) => MsgBox("ok")` | `(*) => { ... }` → syntax error |
| 8 | Backtick escaping | `text := "He said, \`"Hello\`""` | Backslash escaping `\"` — invalid |
| 9 | `gui.Hide()` not `gui.Close()` | `myGui.Hide()` | `myGui.Close()` → MethodError (does not exist in v2) |
| 10 | Never `ErrorLevel` | `try { Run("x.exe") } catch as err { }` | `if (ErrorLevel)` — always unset/wrong in v2 |

### JavaScript Contamination Blockers

AHK v2 is NOT JavaScript. These patterns are **FORBIDDEN**:

- ❌ `const`, `let`, `var` — use explicit `local`, `global`, `static`
- ❌ `===`, `!==`, `??` — use `=`, `!=`, ternary
- ❌ Template literals `` `text ${var}` `` — use concatenation `"text " . var`
- ❌ `addEventListener` — use `OnEvent()`
- ❌ Arrow functions with `{ }` blocks — use named methods + `.Bind(this)`
- ❌ Object literals `{}` for runtime data storage — use `Map()`
- ❌ Array methods like `.map()`, `.filter()` — use AHK loops or functional helpers

### GUI Development Standards

- **Class encapsulation**: ALL GUI code inside a class. No bare top-level `Gui()` calls.
- **Mathematical Y-position tracking** (prevents control overlaps):

```ahk
margin := 10
currentY := margin
windowWidth := 650

title := gui.AddText("x" . margin . " y" . currentY . " w" . (windowWidth-20) . " h25", "Title")
currentY += 35

edit := gui.AddEdit("x" . margin . " y" . currentY . " w" . (windowWidth-20) . " h100")
currentY += 110

gui.Show("w" . windowWidth . " h" . (currentY + margin))
```

- **`Map()` for control storage**: `this.controls := Map()` — never `{}`
- **`.Bind(this)` on all event handlers**: `ctrl.OnEvent("Click", this.Handler.Bind(this))`
- **Single-line callbacks**: `(*) => this.Method()` permitted
- **Multi-line callbacks**: MUST be named method + `.Bind(this)`
- **Build controls once**: Guard with `if !this._built` flag
- **Owner window ordering**: Disable owner before showing owned window; re-enable before destroying owned window.

### Error Handling Patterns

Custom error class template:
```ahk
class AppError extends Error {
    __New(message, code := 0) {
        super.__New(message)
        this.Code := code
    }
}
```

Rules:
- No empty `catch {}` blocks
- Use `try/finally` for resource cleanup (file handles, GUI)
- Use `OnError()` handler registered as first executable statement
- Most-specific `catch` clauses first (broad `catch Error` last)
- Validate params with `ValueError`/`TypeError` rather than `throw`

### Subagent Routing Table

When encountering specific AHK tasks, dispatch a subagent using the prompt template in `.opencode/agents/`:

| Task Type | Subagent | When to Use |
|-----------|----------|-------------|
| Version detection | `ahk-version-detector` | Working with unknown/external .ahk files — scan for v1 syntax before editing |
| Automated v1→v2 | `ahk-converter-runner` | Batch-converting v1 files to v2 using converter tool |
| Manual migration | `v1-to-v2-migrator` | Complex migration where automated conversion fails |
| GUI creation | `gui-builder` | Building new windows, dialogs, or UI components |
| Layout enforcement | `ahk-gui-layout-enforcer` | Fixing overlapping controls, audit GUI positioning |
| Generic layout | `layout` | General layout constraint enforcement |

Usage: `task("description", "general", prompt)` where `prompt` is copied from the agent template file.

### Reference Knowledge Library

Deep AHK v2 reference material is available in `ClautoHotkey/`:
- `ClautoHotkey/Modules/Module_Classes.md` — OOP patterns, meta-functions, factories
- `ClautoHotkey/Modules/Module_GUI.md` — GUI construction, ListView/TreeView CRUD, resize
- `ClautoHotkey/Modules/Module_Errors.md` — error hierarchy, try/catch, diagnostics
- `ClautoHotkey/Modules/Module_Instructions.md` — cognitive tiers, routing table, checklist
- `ClautoHotkey/Modules/Module_Arrays.md` — 1-based arrays, Map/Filter/Reduce
- `ClautoHotkey/Modules/Module_TextProcessing.md` — string ops, regex, escapes
- `ClautoHotkey/Modules/Module_Objects.md` — object hierarchy, property descriptors
- `ClautoHotkey/Modules/Module_DataStructures.md` — Array vs Map selection, iteration
- `ClautoHotkey/Modules/Module_DynamicProperties.md` — DefineProp, closures, computed
- `ClautoHotkey/Modules/Module_ClassPrototyping.md` — runtime class creation, decorators
- `ClautoHotkey/AHK_Notes/` — extensive examples and explanations (60+ files)
- `ClautoHotkey/Tests/` — test scripts and validation tools
```

- [ ] **Step 2: Verify the edit**

Run: `(Get-Item "D:\workspace\AHKestra\AGENTS.md").Length / 1KB`
Expected: File size should increase from ~5KB to ~12KB
Check: Lines should now be ~360-400 (from 130)

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "docs: integrate ClautoHotkey AHK v2 standards into AGENTS.md"
```

---

### Task 2: Create .opencode/agents/ directory and ahk-version-detector

**Files:**
- Create: `.opencode/agents/ahk-version-detector.md`
- Create: `.opencode/.gitkeep`

- [ ] **Step 1: Create directory structure**

```bash
New-Item -ItemType Directory -Path ".opencode\agents" -Force
New-Item -ItemType File -Path ".opencode\.gitkeep" -Force
```

- [ ] **Step 2: Create ahk-version-detector agent template**

Write `.opencode/agents/ahk-version-detector.md`:

```markdown
# Subagent: ahk-version-detector

**Purpose:** AutoHotkey version detection specialist. Scans any .ahk script to determine if it's v1 or v2 before editing.

**When to use:** Before modifying any external/unknown .ahk file. Always run this check first.

## Prompt Template

```
You are an AutoHotkey Version Detection Specialist.

Analyze the script at [FILE_PATH] for v1 syntax patterns:

1. Legacy assignment without :=: `var = value`
2. Variable dereferencing with %: `%var%`
3. Command syntax with comma: `MsgBox, text`
4. Deprecated commands: #NoEnv, SetBatchLines, StringSplit
5. Legacy GUI: `Gui, Add,`
6. `#If` instead of `#HotIf`

Report format:
=== AHK Version Detection Report ===
Script: [filename]
Detected Version: [v1/v2]

v1 Indicators Found:
- [pattern] at line X

Conversion Required: [YES/NO]
```

**Example:**
```
Task: {"description": "Check AHK file version", "subagent_type": "general", "prompt": "You are an AutoHotkey Version Detection Specialist... (use template above)"}
```
```

- [ ] **Step 3: Verify file was created**

Run: `Test-Path ".opencode\agents\ahk-version-detector.md"`
Expected: True

- [ ] **Step 4: Commit**

```bash
git add .opencode/
git commit -m "feat: add ahk-version-detector subagent template"
```

---

### Task 3: Create ahk-converter-runner subagent template

**Files:**
- Create: `.opencode/agents/ahk-converter-runner.md`

- [ ] **Step 1: Create the converter runner agent template**

Write `.opencode/agents/ahk-converter-runner.md`:

```markdown
# Subagent: ahk-converter-runner

**Purpose:** AutoHotkey v2 converter execution specialist. Runs automated v1→v2 conversion when v1 code is detected.

**When to use:** After ahk-version-detector confirms v1 code. For batch conversion of multiple files.

## Prompt Template

```
You are an AutoHotkey v2 Converter Execution Specialist.

Convert the v1 script at [FILE_PATH] to v2:

1. Backup original: FileCopy(script, script . ".v1backup")
2. Run converter (QuickConvertorV2.ahk or manual)
3. Verify output file (*_v2new.ahk)
4. Report conversion status

Key conversion patterns:
- Variables: `var = value` → `var := "value"`
- Commands: `MsgBox, text` → `MsgBox("text")`
- GUI: `Gui, Add, Button` → `gui.AddButton()`
- Objects: `Object()` → `Map()` or `[]`
- Error: `if ErrorLevel` → `try/catch`

Report format:
=== AHK v2 Conversion Report ===
File: [filename]
Status: [SUCCESS/PARTIAL/FAILED]
Changes: [summary]
Manual review needed: [list of items]
```

**Example:**
```
Task: {"description": "Convert v1 AHK script to v2", "subagent_type": "general", "prompt": "You are an AutoHotkey v2 Converter Execution Specialist... (use template above)"}
```
```

- [ ] **Step 2: Commit**

```bash
git add .opencode/agents/ahk-converter-runner.md
git commit -m "feat: add ahk-converter-runner subagent template"
```

---

### Task 4: Create v1-to-v2-migrator subagent template

**Files:**
- Create: `.opencode/agents/v1-to-v2-migrator.md`

- [ ] **Step 1: Create the migration agent template**

Write `.opencode/agents/v1-to-v2-migrator.md`:

```markdown
# Subagent: v1-to-v2-migrator

**Purpose:** Manual v1→v2 migration specialist. Handles complex migrations that automated converters cannot complete.

**When to use:** When automated conversion (ahk-converter-runner) partially fails. For complex edge cases requiring human judgment.

## Prompt Template

```
You are an AutoHotkey v1 to v2 MANUAL migration expert.

Migrate the script at [FILE_PATH] from v1 to v2 manually:

1. Analyze the v1 script structure
2. Identify breaking changes line by line
3. Convert syntax systematically
4. Update to v2 best practices
5. Preserve original functionality

Key conversion areas:
- StringSplit → StrSplit() (different parameter order)
- IfWinExist → WinExist()
- Gosub → Function calls
- #NoEnv → Not needed in v2
- SetBatchLines → Not available in v2
- Legacy GUI g-labels → .OnEvent() binding

Provide the complete converted file, noting any patterns that needed creative interpretation.
```

**Example:**
```
Task: {"description": "Manual v1 to v2 migration", "subagent_type": "general", "prompt": "You are an AutoHotkey v1 to v2 MANUAL migration expert... (use template above)"}
```
```

- [ ] **Step 2: Commit**

```bash
git add .opencode/agents/v1-to-v2-migrator.md
git commit -m "feat: add v1-to-v2-migrator subagent template"
```

---

### Task 5: Create gui-builder subagent template

**Files:**
- Create: `.opencode/agents/gui-builder.md`

- [ ] **Step 1: Create the GUI builder agent template**

Write `.opencode/agents/gui-builder.md`:

```markdown
# Subagent: gui-builder

**Purpose:** AutoHotkey v2 GUI creation specialist. Builds robust, user-friendly interfaces with proper event handling and layout.

**When to use:** Creating new GUI windows, dialogs, or any UI components. Complex event handling scenarios.

## Prompt Template

```
You are an AutoHotkey v2 GUI development expert.

Build a GUI for: [DESCRIBE UI REQUIREMENTS]

Standards:
- Class encapsulation: ALL GUI code inside a class
- Mathematical Y-position tracking (currentY variable)
- Map() for control storage
- .Bind(this) on all event handlers
- gui.Hide() not gui.Close()
- Input validation and clear feedback
- Tab order and keyboard shortcuts
- DPI scaling consideration

Structure:
```ahk
class MyGui {
    __New() {
        this.gui := Gui("+Resize", "Title")
        this.controls := Map()
        this._built := false
        this._build()
    }

    _build() {
        margin := 10
        currentY := margin
        windowWidth := 650
        ; ... controls with currentY tracking ...
        this.gui.Show("w" . windowWidth . " h" . (currentY + margin))
    }
}
```

Provide a complete, runnable class.
```

**Example:**
```
Task: {"description": "Build AHK v2 settings dialog", "subagent_type": "general", "prompt": "You are an AutoHotkey v2 GUI development expert... (use template above)"}
```
```

- [ ] **Step 2: Commit**

```bash
git add .opencode/agents/gui-builder.md
git commit -m "feat: add gui-builder subagent template"
```

---

### Task 6: Create ahk-gui-layout-enforcer subagent template

**Files:**
- Create: `.opencode/agents/ahk-gui-layout-enforcer.md`

- [ ] **Step 1: Create the layout enforcer agent template**

Write `.opencode/agents/ahk-gui-layout-enforcer.md`:

```markdown
# Subagent: ahk-gui-layout-enforcer

**Purpose:** GUI layout enforcement specialist. Audits and fixes control positioning to prevent overlaps using mathematical Y tracking.

**When to use:** Fixing overlapping/misaligned controls. Auditing existing GUI code for positioning errors. Refactoring legacy GUI code.

## Prompt Template

```
You are an AutoHotkey v2 GUI Layout Enforcement Specialist.

Audit and fix the GUI layout in this code: [INSERT GUI CODE]

Enforcement rules:
1. NO hard-coded Y positions (y50, y100 etc.) — ALL Y values derived from currentY
2. MANDATORY: margin, currentY, windowWidth variables at start
3. After EVERY control: currentY += height + spacing
4. Side-by-side controls use calculated X positions: (margin + prevWidth + gap)
5. gui.Show() uses calculated height: "h" . (currentY + margin)
6. GroupBox uses innerY for nested controls

Template:
```ahk
margin := 10
spacing := 10
currentY := margin
windowWidth := 650

; Vertical stack
ctrl := gui.AddText("x" . margin . " y" . currentY . " w" . (windowWidth-20) . " h25")
currentY += 35

; Side-by-side
leftWidth := (windowWidth - 30) / 2
rightX := margin + leftWidth + 10
leftCtrl := gui.AddEdit("x" . margin . " y" . currentY . " w" . leftWidth)
rightCtrl := gui.AddEdit("x" . rightX . " y" . currentY . " w" . leftWidth)
currentY += 35

gui.Show("w" . windowWidth . " h" . (currentY + margin))
```

Return corrected code or diff.
```

**Example:**
```
Task: {"description": "Fix overlapping GUI controls", "subagent_type": "general", "prompt": "You are an AutoHotkey v2 GUI Layout Enforcement Specialist... (use template above)"}
```
```

- [ ] **Step 2: Commit**

```bash
git add .opencode/agents/ahk-gui-layout-enforcer.md
git commit -m "feat: add ahk-gui-layout-enforcer subagent template"
```

---

### Task 7: Create layout subagent template

**Files:**
- Create: `.opencode/agents/layout.md`

- [ ] **Step 1: Create the generic layout agent template**

Write `.opencode/agents/layout.md`:

```markdown
# Subagent: layout

**Purpose:** Generic GUI layout enforcement specialist. Guarantees overlap-free, mathematically positioned layouts with consistent spacing.

**When to use:** General layout constraint implementation. New GUI creation with focus on proper positioning. Refactoring mixed-quality GUI code.

## Prompt Template

```
You are an AutoHotkey v2 GUI layout enforcement specialist.

Generate/review/refactor GUI code with strict mathematical positioning:

[SPECIFY TASK: new GUI / audit existing / refactor mixed code]

Core variables to establish:
```ahk
margin := 10
spacing := 10
currentY := margin
windowWidth := 650
```

Vertical math: nextY := currentY + controlHeight + spacing
Horizontal math: leftWidth := (windowWidth - margin*2 - gap) / 2

Checklist:
[ ] margin, spacing, currentY, windowWidth initialized
[ ] No fixed Y values (scan for regex \by\d+\b)
[ ] Every control increments currentY
[ ] gui.Show() uses dynamic height: "h" . (currentY + margin)
[ ] GroupBox uses innerY for nested controls
[ ] Side-by-side controls use calculated X offsets

Return a clean, runnable class or function block.
```

**Example:**
```
Task: {"description": "Create settings panel with proper layout", "subagent_type": "general", "prompt": "You are an AutoHotkey v2 GUI layout enforcement specialist... (use template above)"}
```
```

- [ ] **Step 2: Commit**

```bash
git add .opencode/agents/layout.md
git commit -m "feat: add layout subagent template"
```

---

### Task 8: Final verification

**Files:**
- Check: `./AGENTS.md`
- Check: `.opencode/agents/*.md` (6 files)

- [ ] **Step 1: Verify all files exist and have content**

```bash
Write-Host "=== AGENTS.md ==="
Write-Host "Size: $((Get-Item AGENTS.md).Length / 1KB) KB"
Write-Host "Lines: $((Get-Content AGENTS.md).Count)"

Write-Host "`n=== .opencode/agents/ ==="
Get-ChildItem -Path ".opencode/agents" -Name | ForEach-Object {
    Write-Host "$_ : $((Get-Item ".opencode/agents/$_").Length) bytes"
}
```

Expected:
- AGENTS.md: ~12KB, ~380 lines, contains "AHK v2 Development Standards" section
- `.opencode/agents/` has 6 .md files, each non-empty

- [ ] **Step 2: Spot-check key content in AGENTS.md**

```bash
Select-String -Path "AGENTS.md" -Pattern "AHK v2 Development Standards" -SimpleMatch
Select-String -Path "AGENTS.md" -Pattern "Subagent Routing Table" -SimpleMatch
Select-String -Path "AGENTS.md" -Pattern "JavaScript Contamination" -SimpleMatch
```

Expected: All three patterns found.

- [ ] **Step 3: Final commit if any changes remain**

```bash
git add -A
git status
```
Expected: clean working tree (nothing to commit) if all tasks committed properly. If not, commit remaining changes.
```
