# AGENTS.md - AHKestra

## Project Overview

AHKestra is an AutoHotkey v2 (AHK v2) context-aware automation framework for Windows. It includes a C# helper library (`AHKestra.Tools.Json`) for JSON schema validation. The codebase is primarily written in AutoHotkey v2 with a small C#/.NET 8.0 component.

## Project Structure

```
src/
  AHKestra/                    # Main AHK v2 application
    AHKestra.ahk               # Entry point
    Core/
      Api/                     # Public plugin API surface
      Common/                  # Shared utilities (ConfigService, Errors, etc.)
      Conditions/              # Condition evaluation engine
      Contexts/                # Context assembly and providers
      Events/                  # Event bus and providers
      Infrastructure/          # System-level services (MonitorService)
      Managers/                # Feature managers (Hotkey, ContextMenu, TextEngine)
      Plugins/                 # Plugin lifecycle management
      Views/                   # GUI components
    Lib/                       # Third-party AHK libraries (JSON, Yaml, WinEvent, Monitor)
  AHKestra.Tools.Json/         # C# DLL for manifest validation
docs/                          # Documentation scripts
assets/                        # Icons and themes
```

## Build / Run / Test Commands

### Running the Application

```bash
# Requires AutoHotkey v2.0 installed
autohotkey.exe src\AHKestra\AHKestra.ahk
```

### Building the C# Helper DLL

```bash
cd src\AHKestra.Tools.Json
dotnet build -c Release
```

### Building the Executable (Ahk2Exe)

Use the `;@Ahk2Exe-*` directives in `AHKestra.ahk` with the Ahk2Exe compiler to produce `AHKestra.exe`.

### Running the API Doc Generator

```bash
autohotkey.exe docs\GenerateAPI.ahk
```

### Testing

There is no formal test framework. Validate changes by:
1. Running the application and testing plugin loading, hotkey registration, and context/menu behavior manually.
2. Building the C# project (`dotnet build`) to verify C# compilation.
3. Checking that the `dotnet build` command completes without errors is the primary automated verification.

## Code Style Guidelines

### General

- This is an AutoHotkey v2 project. All `.ahk` files must start with `#Requires AutoHotkey v2.0` when they are top-level entry points.
- Use `#SingleInstance Force` in the main script only.
- Indentation: 4 spaces for `.ahk` files, 4 spaces for `.cs` files.

### AHK v2 Conventions

- **Classes**: PascalCase (e.g., `ContextService`, `PluginService`, `EventBus`)
- **Static methods / Public API**: PascalCase (e.g., `GetContext()`, `Register()`, `Evaluate()`)
- **Private methods**: camelCase with underscore prefix (e.g., `_loadAllPlugins`, `_onWindowActivated`, `_unregisterContributions`)
- **Variables**: camelCase (e.g., `pluginName`, `finalContext`, `hotkeyDef`)
- **Constants**: UPPER_SNAKE_CASE as global variables (e.g., `APP_VERSION`, `APP_PLUGINS_DIR`)
- **Parameters in JSDoc**: Use `{Type}` annotations (e.g., `@param pluginName {String}`)

### Class Patterns

- **Services** use `static` properties and methods exclusively — no instantiation (e.g., `ContextService`, `ConfigService`, `EventBus`).
- **Providers** implement interface-like base classes that throw `NotImplementedError()` (e.g., `IConditionProvider`, `IEventProvider`).
- **Plugin classes** extend `Plugin` base class and override lifecycle methods: `OnEnable()`, `OnDisable()`, `OnLoad()`, `OnUninstall()`.
- Use `local` keyword for local variables to avoid global scope pollution.

### Imports (AHK v2)

- Use `#Include` with `%A_ScriptDir%` relative paths for application files.
- Use `#Include <LibraryName>` for library-style includes (e.g., `#Include <Core\Api\Events>`).
- Group includes logically: API surface first, then services, then managers, then views.

### Imports (C#)

- Follow standard .NET conventions.
- Namespace must match `<RootNamespace>` in `.csproj` (currently `AHKestra`).
- Use `System.Text.Json` for JSON serialization.
- DllExport functions use `StdCall` calling convention with `LPWStr` marshaling.

### Error Handling

- Wrap risky operations in `try...catch Error as e` blocks.
- Use custom error classes for domain-specific errors (e.g., `NotImplementedError` extends `Error`).
- Log errors via `OutputDebug()` for development visibility; `PluginService.Log()` for plugin-facing logging.
- Throw `ValueError` for invalid arguments, `Error` for general runtime failures.
- When re-throwing, chain errors: `throw Error("message", -1, e)`.

### Documentation

- Use JSDoc-style block comments (`/** ... */`) for class and method documentation.
- Include `@param` and `@returns` tags with type annotations.
- Comments and documentation are written in Chinese (简体中文) for user-facing descriptions.
- Section headers in large classes use `; ====` comment blocks for visual separation.

### C# Code Style

- Standard C# naming: PascalCase for public members, camelCase for private.
- Use `record` types for DTOs (e.g., `ValidationResult`, `ErrorDetail`).
- Use `Nullable` reference types (enabled in `.csproj`).
- Catch broad `Exception` at DllExport boundaries, return structured error JSON.

### JSON / Manifest Files

- Plugin manifests use `manifest.json` with a defined schema validated by the C# `JsonTools` library.
- Configuration uses JSON files managed by `ConfigService`.
- Hotkey definitions use AHK modifier syntax: `^` (Ctrl), `!` (Alt), `+` (Shift), `#` (Win).

### Commit Messages

- Follow [gitmoji](https://gitmoji.dev/) conventions (e.g., `feat: Add AmazingFeature`).
- Use conventional commit prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`.

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
