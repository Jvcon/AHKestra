# AHKestra 🎹

<div align="center">
  <p><strong>The Context-Aware Automation Conductor for Windows</strong></p>
  <p>
    一款基于 AutoHotkey v2 的次世代效率工具集，它能像指挥家一样，智能地编排和指挥您的工作流。
  </p>

  <!-- Badges -->
  <p>
    <a href="https://github.com/YourUsername/AHKestra/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg" alt="License"></a>
    <a href="https://github.com/YourUsername/AHKestra/releases"><img src="https://img.shields.io/github/v/release/YourUsername/AHKestra" alt="Latest Release"></a>
    <a href="https://github.com/YourUsername/AHKestra/actions/workflows/build.yml"><img src="https://github.com/YourUsername/AHKestra/actions/workflows/build.yml/badge.svg" alt="Build Status"></a>
    <a href="https://www.autohotkey.com/"><img src="https://img.shields.io/badge/Powered%20by-AutoHotkey%20v2-blueviolet" alt="Powered by AutoHotkey v2"></a>
    <a href="https://github.com/YourUsername/AHKestra/graphs/contributors"><img src="https://img.shields.io/github/contributors/YourUsername/AHKestra" alt="Contributors"></a>
  </p>
</div>

**AHKestra** 是一款开源、可扩展的 Windows 效率工具。它不仅仅是快捷键或热字符串的简单集合，而是一个拥有统一设计哲学、以“上下文感知”为核心的智能框架。它能深刻理解您当前的工作环境（正在使用什么软件、是否选中了文本等），并动态地为您提供最精准、最相关的工具和操作。

## ✨ 核心特性

* 🧠 **深度上下文感知 (Context-Aware Core)**：框架的核心能力。无论是快捷键、右键菜单还是文本操作，其行为都会根据当前激活的应用、窗口状态、选中的文本等上下文智能地变化。
* 🔌 **声明式插件框架 (Declarative Plugin Framework)**：通过简单的 `manifest.json` 文件，插件开发者可以轻松地为 AHKestra 贡献新功能，无需关心底层复杂的实现。
* 🎹 **统一的交互模型 (Unified Interaction Model)**：智能的统一右键菜单和 `which-key` 风格的热键引导系统，极大地降低了用户的记忆负担。您只需记住少数入口，即可指挥整个“乐团”。
* ✍️ **强大的文本引擎 (Powerful Text Engine)**：集成了兼容 Espanso 配置的文本扩展（热字符串）和强大的文本动作引擎，让文本处理行云流水。
* 🚀 **专为效率打造 (Built for Efficiency)**：基于 AutoHotkey v2 构建，性能卓越，响应迅速。

## 🚀 使用方式

您可以选择直接使用我们编译好的二进制文件，或从源代码运行。

### 🧑‍💻 对于用户 (二进制文件)

1. 前往 [Releases 页面](https://github.com/YourUsername/AHKestra/releases) 下载最新的 `AHKestra-vX.X.X.zip` 文件。
2. 解压到您喜欢的任意位置。
3. 运行 `AHKestra.exe`。
4. 程序将在系统托盘中显示一个 🎹 图标，右键点击图标可进行设置。

### 🛠️ 对于开发者 (从源代码运行)

1. 确保您已安装 [AutoHotkey v2.0](https://www.autohotkey.com/)。
2. 克隆本仓库：

    ```bash
    git clone https://github.com/YourUsername/AHKestra.git
    ```

3. 进入项目目录并运行主脚本：

    ```bash
    cd AHKestra
    autohotkey.exe Main.ahk
    ```

## 🏛️ 框架设计理念

AHKestra 的强大之处在于其独特的设计哲学，它将几个核心概念无缝地融合在一起：

1. **全场景上下文 (`ContextInfo`)**：我们构建了一个强大的上下文信息中心，它不仅能感知窗口、进程，还能主动获取选中的文本、剪贴板内容等多种文本源，为所有模块提供“全知”的上下文对象。这是实现一切智能化的基础。

2. **插件化的上下文扩展 (Pluggable Context Providers)**：我们深知，通用的上下文信息无法满足所有高级需求。因此，AHKestra 设计了一个**可插拔的上下文提供者 (Context Provider) 框架**。任何插件都可以为特定的应用程序（如 Total Commander、Photoshop）注册自己的深度上下文提供者。当该应用激活时，框架会自动调用此提供者，将如“活动面板路径”、“当前图层名称”等深度信息，动态地注入到全局上下文对象中。这使得 AHKestra 的感知能力可以被社区无限扩展。

3. **通用条件库 (`Conditions`)**：为了减少插件开发者的重复工作，我们提供了一个包含大量常用判断逻辑的通用条件库。插件可以直接在 `manifest.json` 中声明使用这些条件（如 `isBrowser`、`hasSelection`）。

4. **智能分发器 (`ConditionHelper`)**：这是框架的决策中枢。它会自动评估一个功能（快捷键或菜单项）的条件。这个过程非常智能：它会**优先在通用条件库中查找**，如果找不到，则**回退到插件自定义的条件函数**。这种机制在为您提供便利的同时，也保证了最大的灵活性。

5. **统一的声明式接口 (`manifest.json`)**：所有功能的贡献都通过统一的 `manifest.json` 进行。无论是快捷键、右键菜单，还是文本扩展，插件都以一种清晰、解耦的方式声明其“意图”，由框架负责实现。这种设计理念与许多现代应用（如 **Stream Deck**）通过插件系统进行功能扩展的方式不谋而合 [My Stream Deck Setup](https://switowski.com/blog/my-stream-deck-setup/){target="_blank" class="gpt-web-url"}。

## 🧩 插件开发指南

为 AHKestra 开发插件非常简单！您只需要创建一个文件夹，并在其中包含 `manifest.json` 和一个主 `.ahk` 文件即可。

### 1. 目录结构

```
📂 Plugins/
└── 📂 MyCoolPlugin/
    ├── 📄 manifest.json
    └── 📄 MyCoolPlugin.ahk
```

### 2. `manifest.json` 示例

这是插件的“身份证”和“功能说明书”。

```json
{
    "name": "MyCoolPlugin",
    "version": "1.0.1",
    "author": "Your Name",
    "description": "一个演示插件，展示了如何注册快捷键和菜单项。",
    "main": "MyCoolPlugin.ahk",
    "contributes": {
        "hotkeys": [
            {
                "keys": ["^!p"],
                "type": "regular",
                "function": "showPluginMessage",
                "hint": "显示插件信息"
            }
        ],
        "menuItems": [
            {
                "path": "我的插件/显示信息",
                "function": "showPluginMessage",
                "condition": "isNotepadActive" 
            }
        ]
    }
}
```

### 3. `MyCoolPlugin.ahk` 示例

这是实现插件功能的地方。

```autohotkey
#Requires AutoHotkey v2.0

class Plugin {
    __New(context) {
        ; 构造函数，在插件加载时调用
        this.context := context
    }

    ; --- 回调函数 ---
    showPluginMessage(ctx) {
        MsgBox "Hello from " . this.context.name . "!`nActive Window: " . ctx.ActiveWindow.title
    }

    ; --- 自定义条件函数 ---
    isNotepadActive(ctx) {
        return ctx.ActiveWindow.processName == "notepad.exe"
    }
}
```

### 4. 🚀 进阶：插件注册上下文提供者

这是 AHKestra 最强大的功能之一。如果您的插件需要感知特定应用程序的内部状态（例如，Total Commander 的活动面板，或代码编辑器中光标所在的函数名），您可以注册一个**上下文提供者 (Context Provider)**。这使得您的插件能够创造出真正“**上下文敏感 (context-sensitive)**”的菜单和热键。

假设我们正在开发一个针对 Total Commander 的增强插件：

**`Plugins/EnhanceTC/EnhanceTC.ahk`**

```autohotkey
#Requires AutoHotkey v2.0

class Plugin {
    __New(context) {
        this.context := context
    }
    
    /**
     * 在插件加载后，框架会自动调用此 Init 方法。
     * 这是进行程序化注册的最佳位置。
     */
    Init() {
        // 向核心框架注册一个针对 TOTALCMD.EXE 的上下文提供者
        ContextInfo.RegisterProvider("TOTALCMD.EXE", this.getTCSpecificContext.Bind(this))
        ContextInfo.RegisterProvider("TOTALCMD64.EXE", this.getTCSpecificContext.Bind(this))
    }

    /**
     * 这是我们自定义的上下文提供者函数。
     * 当 Total Commander 激活时，它会被框架自动调用。
     * @param baseContext {Object} 框架提供的基础上下文对象。
     * @returns {Map} 一个包含TC专属上下文信息的Map，它将被合并到最终的context对象中。
     */
    getTCSpecificContext(baseContext) {
        local tcContext := Map()
        
        // 使用 AHK 的底层能力获取 TC 内部状态
        tcContext["activePanelPath"] := ControlGetText("TPathEdit" . (this._isLeftPanelActive() ? "1" : "2"), "ahk_id " . baseContext.ActiveWindow.hwnd)
        tcContext["selectedFilesCount"] := this._getSelectedFilesCount()
        
        return tcContext
    }

    // --- 插件内部的辅助方法 ---
    _isLeftPanelActive() { /* ... */ }
    _getSelectedFilesCount() { /* ... */ }

    // --- 插件现在可以使用这些深度上下文了 ---
    isSomethingSelectedInTC(ctx) {
        // ctx 对象现在已经包含了我们刚刚注入的 'selectedFilesCount'
        return IsSet(ctx.selectedFilesCount) && ctx.selectedFilesCount > 0
    }
}
```

通过这种方式，您可以为任何您想要深度集成的应用程序编写增强插件。无论是 **Total Commander** 还是其他可以通过脚本控制的软件，AHKestra 都为您提供了无限的可能性。

## 📜 开源许可

本项目采用 **Mozilla Public License 2.0 (MPL 2.0)** 许可证。

简单来说，这意味着：

* ✅ **您可以** 自由地使用、修改和分发本软件。
* ✅ **您可以** 在您的商业或闭源项目中使用 AHKestra。
* ✅ **您可以** 编写商业闭源的插件并在 AHKestra 上运行。
* ⚠️ **您必须** 在任何分发版本中保留原始的版权和许可证声明。
* 🔄 **如果您修改了 AHKestra 的核心文件**，您必须将这些修改以同样的 MPL 2.0 许可证开源。

完整的许可证文本请参见 [LICENSE](./LICENSE) 文件。

## 🤝 贡献规范

我们非常欢迎来自社区的贡献！无论是报告 Bug、提交功能请求，还是直接贡献代码。正如一份 **GitHub 指南**所说，一个清晰的贡献流程对开源项目至关重要 [GitHub for Collaboration On Open Projects](https://mozillascience.github.io/working-open-workshop/github_for_collaboration/){target="_blank" class="gpt-web-url"}。

1. **Fork** 本仓库。
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)。
3. 提交您的更改 (`git commit -m 'feat: Add some AmazingFeature'`)。我们推荐使用 [gitmoji](https://gitmoji.dev/){target="_blank" class="gpt-web-url"} 来规范您的提交信息。
4. 推送到分支 (`git push origin feature/AmazingFeature`)。
5. 打开一个 **Pull Request**。

在提交 Pull Request 前，请确保您的代码遵循项目现有的编码风格。更详细的贡献指南，请参见 `CONTRIBUTING.md` (待创建)。

---

感谢所有为这个项目提供灵感和贡献的人。我们期待看到您用 **AHKestra** 指挥出属于您自己的、华丽的效率乐章！
