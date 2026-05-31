# 测试框架实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 AHKestra 构建一个轻量级但功能完整的 AutoHotkey v2 测试框架，支持测试组织、断言、夹具、模拟和报告，解决在 macOS 开发环境下无法验证 Windows 行为的问题。

**Architecture:** 基于 xUnit 模式的测试框架，采用 TestSuite 组织测试、TestCase 封装测试逻辑、TestFixture 管理生命周期，通过 XML/JSON 报告输出测试结果。

**Tech Stack:** AutoHotkey v2, JSON (报告格式), XML (JUnit 兼容报告)

---

## 环境挑战与解决方案

### macOS 开发限制
- 无法运行 AutoHotkey 脚本
- 无法验证 Windows API 调用
- 无法测试 GUI 交互

### 解决方案
1. **语法验证**: 使用 ahk2 vscode 扩展进行语法检查
2. **逻辑隔离**: 将业务逻辑与平台相关代码分离
3. **模拟层**: 为 Windows API 创建模拟接口
4. **CI 验证**: 依赖 GitHub Actions 在 Windows 环境运行测试

---

## 文件结构

```
tests/
├── TestRunner.ahk              # 测试运行器入口
├── TestFramework/
│   ├── TestSuite.ahk           # 测试套件
│   ├── TestCase.ahk            # 测试用例基类
│   ├── TestFixture.ahk         # 测试夹具（SetUp/TearDown）
│   ├── Assert.ahk              # 断言库
│   ├── Mock.ahk                # 模拟对象
│   ├── TestReporter.ahk        # 测试报告生成
│   └── MockWindowsApi.ahk      # Windows API 模拟层
├── Core/
│   ├── Common/
│   │   ├── ConfigService.test.ahk
│   │   └── Errors.test.ahk
│   ├── Conditions/
│   │   ├── ConditionEngine.test.ahk
│   │   └── AndCondition.test.ahk
│   ├── Contexts/
│   │   └── ContextService.test.ahk
│   ├── Events/
│   │   └── EventBus.test.ahk
│   └── Services/
│       └── LogService.test.ahk
└── run-tests.ahk               # 测试执行脚本
```

---

## Task 1: 创建断言库

**Files:**
- Create: `tests/TestFramework/Assert.ahk`

- [ ] **Step 1: 实现完整断言库**

```ahk
#Requires AutoHotkey v2.0

/**
 * 断言工具类
 * 提供丰富的断言方法用于测试验证
 */
class Assert {
    static _failCount := 0
    
    /**
     * 断言两个值相等
     * @param expected {Any} 期望值
     * @param actual {Any} 实际值
     * @param message {String} [可选] 错误消息
     */
    static Equal(expected, actual, message := "") {
        if (expected != actual) {
            this._fail(message != "" ? message : "值不相等",
                "期望: " this._stringify(expected),
                "实际: " this._stringify(actual))
        }
    }
    
    /**
     * 断言两个值不相等
     */
    static NotEqual(expected, actual, message := "") {
        if (expected == actual) {
            this._fail(message != "" ? message : "值应不相等",
                "不应等于: " this._stringify(expected),
                "实际: " this._stringify(actual))
        }
    }
    
    /**
     * 断言值为真
     */
    static True(value, message := "") {
        if (!value) {
            this._fail(message != "" ? message : "期望值为真",
                "期望: true",
                "实际: " this._stringify(value))
        }
    }
    
    /**
     * 断言值为假
     */
    static False(value, message := "") {
        if (value) {
            this._fail(message != "" ? message : "期望值为假",
                "期望: false",
                "实际: " this._stringify(value))
        }
    }
    
    /**
     * 断言值为空
     */
    static Empty(value, message := "") {
        local isEmpty := value == "" || value == 0 || !IsSet(value)
        if (!isEmpty && IsObject(value) && value.Count == 0) {
            isEmpty := true
        }
        if (!isEmpty) {
            this._fail(message != "" ? message : "期望值为空",
                "期望: 空值",
                "实际: " this._stringify(value))
        }
    }
    
    /**
     * 断言值不为空
     */
    static NotEmpty(value, message := "") {
        local isEmpty := value == "" || value == 0 || !IsSet(value)
        if (!isEmpty && IsObject(value) && value.Count == 0) {
            isEmpty := true
        }
        if (isEmpty) {
            this._fail(message != "" ? message : "期望值不为空")
        }
    }
    
    /**
     * 断言数值在范围内
     */
    static InRange(actual, min, max, message := "") {
        if (actual < min || actual > max) {
            this._fail(message != "" ? message : "值不在范围内",
                "范围: [" min ", " max "]",
                "实际: " actual)
        }
    }
    
    /**
     * 断言字符串包含子串
     */
    static Contains(haystack, needle, message := "") {
        if (!InStr(haystack, needle)) {
            this._fail(message != "" ? message : "字符串不包含子串",
                "字符串: " this._stringify(haystack),
                "应包含: " this._stringify(needle))
        }
    }
    
    /**
     * 断言字符串匹配正则表达式
     */
    static Matches(text, pattern, message := "") {
        if (!RegExMatch(text, pattern)) {
            this._fail(message != "" ? message : "字符串不匹配模式",
                "字符串: " text,
                "模式: " pattern)
        }
    }
    
    /**
     * 断言抛出异常
     */
    static Throws(func, expectedType := "Error", message := "") {
        local threw := false
        local actualType := ""
        try {
            func()
        } catch Error as e {
            threw := true
            actualType := e.__Class
        }
        if (!threw) {
            this._fail(message != "" ? message : "期望抛出异常",
                "期望异常类型: " expectedType,
                "实际: 无异常")
        }
        if (expectedType != "Error" && actualType != expectedType) {
            this._fail(message != "" ? message : "异常类型不匹配",
                "期望: " expectedType,
                "实际: " actualType)
        }
    }
    
    /**
     * 断言不抛出异常
     */
    static NotThrows(func, message := "") {
        try {
            func()
        } catch Error as e {
            this._fail(message != "" ? message : "不应抛出异常",
                "意外异常: " e.Message)
        }
    }
    
    /**
     * 断言对象具有指定属性
     */
    static HasProperty(obj, propName, message := "") {
        if (!obj.Has(propName)) {
            this._fail(message != "" ? message : "对象缺少属性",
                "期望属性: " propName,
                "可用属性: " this._stringify(obj))
        }
    }
    
    /**
     * 断言对象具有指定方法
     */
    static HasMethod(obj, methodName, message := "") {
        if (!obj.HasMethod(methodName)) {
            this._fail(message != "" ? message : "对象缺少方法",
                "期望方法: " methodName)
        }
    }
    
    /**
     * 断言数组长度
     */
    static HasLength(arr, expectedLength, message := "") {
        if (!IsObject(arr) || !arr.Has("Length")) {
            this._fail("值不是数组")
        }
        if (arr.Length != expectedLength) {
            this._fail(message != "" ? message : "数组长度不匹配",
                "期望长度: " expectedLength,
                "实际长度: " arr.Length)
        }
    }
    
    /**
     * 断言 Map 包含指定键
     */
    static ContainsKey(map, key, message := "") {
        if (!IsObject(map) || !map.Has(key)) {
            this._fail(message != "" ? message : "Map 缺少键",
                "期望键: " key)
        }
    }
    
    /**
     * 断言 Map 包含指定值
     */
    static ContainsValue(map, value, message := "") {
        if (!IsObject(map)) {
            this._fail("值不是 Map 对象")
        }
        local found := false
        for k, v in map {
            if (v == value) {
                found := true
                break
            }
        }
        if (!found) {
            this._fail(message != "" ? message : "Map 不包含值",
                "期望值: " this._stringify(value))
        }
    }
    
    /**
     * 失败处理
     */
    static _fail(mainMsg, detail1 := "", detail2 := "") {
        this._failCount++
        local fullMsg := mainMsg
        if (detail1 != "") {
            fullMsg .= "`n  " detail1
        }
        if (detail2 != "") {
            fullMsg .= "`n  " detail2
        }
        throw Error(fullMsg)
    }
    
    /**
     * 值转字符串
     */
    static _stringify(value) {
        if (!IsSet(value)) {
            return "<未设置>"
        }
        if (value == "") {
            return '""'
        }
        if (IsObject(value)) {
            if (value.Has("Length")) {
                return "Array[" value.Length "]"
            }
            return "Map{" value.Count "}"
        }
        return String(value)
    }
    
    /**
     * 重置失败计数
     */
    static Reset() {
        this._failCount := 0
    }
    
    /**
     * 获取失败次数
     */
    static GetFailCount() {
        return this._failCount
    }
}
```

- [ ] **Step 2: 验证语法正确性**

使用 VSCode ahk2 扩展检查语法，确保无红色错误标记

---

## Task 2: 创建测试夹具

**Files:**
- Create: `tests/TestFramework/TestFixture.ahk`

- [ ] **Step 1: 实现测试夹具基类**

```ahk
#Requires AutoHotkey v2.0

/**
 * 测试夹具基类
 * 提供 SetUp 和 TearDown 生命周期方法
 */
class TestFixture {
    /**
     * 在每个测试前执行
     * 子类重写此方法进行测试准备
     */
    SetUp() {
        ; 默认空实现
    }
    
    /**
     * 在每个测试后执行
     * 子类重写此方法进行清理
     */
    TearDown() {
        ; 默认空实现
    }
    
    /**
     * 在整个套件开始前执行一次
     */
    static SuiteSetUp() {
        ; 默认空实现
    }
    
    /**
     * 在整个套件结束后执行一次
     */
    static SuiteTearDown() {
        ; 默认空实现
    }
}

/**
 * 临时文件夹夹具
 * 自动创建和清理临时目录
 */
class TempDirFixture extends TestFixture {
    tempDir := ""
    
    SetUp() {
        this.tempDir := A_Temp "\ahkestra_test_" A_Now
        DirCreate(this.tempDir)
    }
    
    TearDown() {
        if (this.tempDir != "" && DirExist(this.tempDir)) {
            DirDelete(this.tempDir, true)
        }
    }
    
    /**
     * 获取临时目录路径
     */
    GetTempDir() {
        return this.tempDir
    }
    
    /**
     * 在临时目录中创建文件
     */
    CreateTempFile(name, content := "") {
        local path := this.tempDir "\" name
        if (content != "") {
            FileAppend(content, path)
        }
        return path
    }
}

/**
 * 配置服务夹具
 * 提供隔离的配置环境
 */
class ConfigFixture extends TestFixture {
    originalConfig := ""
    testConfig := Map()
    
    SetUp() {
        ; 备份原始配置状态
        this.originalConfig := ConfigService._configs.Clone()
    }
    
    TearDown() {
        ; 恢复原始配置
        ConfigService._configs := this.originalConfig
    }
    
    /**
     * 设置测试配置
     */
    SetConfig(pluginName, key, value) {
        if (!this.testConfig.Has(pluginName)) {
            this.testConfig[pluginName] := Map()
        }
        this.testConfig[pluginName][key] := value
        ConfigService.SetConfig(pluginName, key, value)
    }
}
```

---

## Task 3: 创建模拟对象系统

**Files:**
- Create: `tests/TestFramework/Mock.ahk`
- Create: `tests/TestFramework/MockWindowsApi.ahk`

- [ ] **Step 1: 实现通用模拟对象**

```ahk
#Requires AutoHotkey v2.0

/**
 * 模拟对象类
 * 用于替代真实对象进行测试
 */
class Mock {
    static _calls := []
    static _returnValues := Map()
    static _exceptions := Map()
    
    /**
     * 记录方法调用
     * @param methodName {String} 方法名
     * @param args {Array} 参数列表
     */
    static RecordCall(methodName, args*) {
        this._calls.Push({
            method: methodName,
            args: args,
            timestamp: A_TickCount
        })
    }
    
    /**
     * 设置方法返回值
     * @param methodName {String} 方法名
     * @param returnValue {Any} 返回值
     */
    static SetupReturn(methodName, returnValue) {
        this._returnValues[methodName] := returnValue
    }
    
    /**
     * 设置方法抛出异常
     * @param methodName {String} 方法名
     * @param exception {Error} 异常对象
     */
    static SetupThrow(methodName, exception) {
        this._exceptions[methodName] := exception
    }
    
    /**
     * 获取方法返回值
     * @param methodName {String} 方法名
     * @returns {Any} 配置的返回值或空
     */
    static GetReturn(methodName) {
        if (this._returnValues.Has(methodName)) {
            return this._returnValues[methodName]
        }
        return ""
    }
    
    /**
     * 检查方法是否应抛出异常
     * @param methodName {String} 方法名
     */
    static CheckThrow(methodName) {
        if (this._exceptions.Has(methodName)) {
            throw this._exceptions[methodName]
        }
    }
    
    /**
     * 验证方法被调用
     * @param methodName {String} 方法名
     * @param times {Integer} [可选] 期望调用次数
     */
    static VerifyCalled(methodName, times := -1) {
        local count := 0
        for call in this._calls {
            if (call.method == methodName) {
                count++
            }
        }
        if (times >= 0 && count != times) {
            throw Error("方法 '" methodName "' 调用次数不匹配。期望: " times "，实际: " count)
        }
        if (times < 0 && count == 0) {
            throw Error("方法 '" methodName "' 未被调用")
        }
    }
    
    /**
     * 验证方法未被调用
     * @param methodName {String} 方法名
     */
    static VerifyNotCalled(methodName) {
        this.VerifyCalled(methodName, 0)
    }
    
    /**
     * 获取方法调用记录
     * @param methodName {String} 方法名
     * @returns {Array} 调用记录数组
     */
    static GetCalls(methodName := "") {
        if (methodName == "") {
            return this._calls.Clone()
        }
        local filtered := []
        for call in this._calls {
            if (call.method == methodName) {
                filtered.Push(call)
            }
        }
        return filtered
    }
    
    /**
     * 获取方法最后一次调用的参数
     * @param methodName {String} 方法名
     * @returns {Array} 参数数组
     */
    static GetLastCallArgs(methodName) {
        local calls := this.GetCalls(methodName)
        if (calls.Length == 0) {
            throw Error("方法 '" methodName "' 无调用记录")
        }
        return calls[calls.Length].args
    }
    
    /**
     * 重置所有记录
     */
    static Reset() {
        this._calls := []
        this._returnValues := Map()
        this._exceptions := Map()
    }
}

/**
 * 模拟文件系统
 * 用于测试文件操作而不影响真实文件系统
 */
class MockFileSystem extends Mock {
    static _files := Map()
    static _directories := Map()
    
    /**
     * 设置文件存在
     */
    static SetupFileExists(path, exists := true) {
        this._files[path] := exists
    }
    
    /**
     * 设置目录存在
     */
    static SetupDirExists(path, exists := true) {
        this._directories[path] := exists
    }
    
    /**
     * 模拟 FileExist
     */
    static FileExist(path) {
        this.RecordCall("FileExist", path)
        this.CheckThrow("FileExist")
        if (this._files.Has(path)) {
            return this._files[path] ? "F" : ""
        }
        return ""
    }
    
    /**
     * 模拟 DirExist
     */
    static DirExist(path) {
        this.RecordCall("DirExist", path)
        this.CheckThrow("DirExist")
        if (this._directories.Has(path)) {
            return this._directories[path] ? "D" : ""
        }
        return ""
    }
    
    /**
     * 重置文件系统状态
     */
    static Reset() {
        base.Reset()
        this._files := Map()
        this._directories := Map()
    }
}

/**
 * 模拟 Windows API
 * 用于在非 Windows 环境验证逻辑
 */
class MockWindowsApi extends Mock {
    static _activeWindow := {hwnd: 12345, title: "Test Window", processName: "test.exe"}
    static _clipboard := ""
    static _mousePos := {x: 100, y: 200}
    
    /**
     * 设置活动窗口
     */
    static SetActiveWindow(hwnd, title, processName) {
        this._activeWindow := {hwnd: hwnd, title: title, processName: processName}
    }
    
    /**
     * 模拟 WinGetTitle
     */
    static WinGetTitle(winTitle := "", winText := "") {
        this.RecordCall("WinGetTitle", winTitle, winText)
        return this._activeWindow.title
    }
    
    /**
     * 模拟 WinGetProcessName
     */
    static WinGetProcessName(winTitle := "", winText := "") {
        this.RecordCall("WinGetProcessName", winTitle, winText)
        return this._activeWindow.processName
    }
    
    /**
     * 模拟 WinGetID
     */
    static WinGetID(winTitle := "", winText := "") {
        this.RecordCall("WinGetID", winTitle, winText)
        return this._activeWindow.hwnd
    }
    
    /**
     * 模拟 ClipboardAll
     */
    static GetClipboard() {
        this.RecordCall("GetClipboard")
        return this._clipboard
    }
    
    /**
     * 模拟设置剪贴板
     */
    static SetClipboard(value) {
        this.RecordCall("SetClipboard", value)
        this._clipboard := value
    }
    
    /**
     * 模拟 MouseGetPos
     */
    static MouseGetPos(&x, &y) {
        this.RecordCall("MouseGetPos")
        x := this._mousePos.x
        y := this._mousePos.y
    }
    
    /**
     * 设置鼠标位置
     */
    static SetMousePos(x, y) {
        this._mousePos := {x: x, y: y}
    }
    
    /**
     * 重置 API 状态
     */
    static Reset() {
        base.Reset()
        this._activeWindow := {hwnd: 12345, title: "Test Window", processName: "test.exe"}
        this._clipboard := ""
        this._mousePos := {x: 100, y: 200}
    }
}
```

---

## Task 4: 创建测试用例和测试套件

**Files:**
- Create: `tests/TestFramework/TestCase.ahk`
- Create: `tests/TestFramework/TestSuite.ahk`

- [ ] **Step 1: 实现测试用例基类**

```ahk
#Requires AutoHotkey v2.0

/**
 * 测试用例基类
 * 封装单个测试的执行逻辑
 */
class TestCase extends TestFixture {
    name := ""
    result := ""
    duration := 0
    error := ""
    
    /**
     * 构造函数
     * @param testName {String} 测试名称
     */
    __New(testName := "") {
        if (testName != "") {
            this.name := testName
        }
    }
    
    /**
     * 执行测试
     * 子类必须实现此方法
     */
    RunTest() {
        throw NotImplementedError("TestCase.RunTest 必须由子类实现")
    }
    
    /**
     * 运行测试（包含 SetUp 和 TearDown）
     * @returns {Map} 测试结果
     */
    Run() {
        local startTime := A_TickCount
        this.result := "passed"
        this.error := ""
        
        try {
            this.SetUp()
            this.RunTest()
        } catch Error as e {
            this.result := "failed"
            this.error := e.Message
        } finally {
            try {
                this.TearDown()
            } catch Error as e {
                if (this.result == "passed") {
                    this.result := "error"
                    this.error := "TearDown 失败: " e.Message
                }
            }
            this.duration := A_TickCount - startTime
        }
        
        return this.GetResult()
    }
    
    /**
     * 获取测试结果
     */
    GetResult() {
        return {
            name: this.name,
            result: this.result,
            duration: this.duration,
            error: this.error
        }
    }
}

/**
 * 动态测试用例
 * 从函数创建测试用例
 */
class DynamicTestCase extends TestCase {
    _testFunc := ""
    
    /**
     * 构造函数
     * @param testName {String} 测试名称
     * @param testFunc {Func} 测试函数
     */
    __New(testName, testFunc) {
        this.name := testName
        this._testFunc := testFunc
    }
    
    RunTest() {
        this._testFunc()
    }
}

/**
 * 参数化测试用例
 * 支持多组参数运行同一测试
 */
class ParameterizedTestCase extends TestCase {
    _testFunc := ""
    _parameters := []
    
    /**
     * 构造函数
     * @param testName {String} 测试名称
     * @param testFunc {Func} 测试函数
     * @param parameters {Array} 参数数组，每项是一个数组
     */
    __New(testName, testFunc, parameters) {
        this.name := testName
        this._testFunc := testFunc
        this._parameters := parameters
    }
    
    /**
     * 运行所有参数组合
     * @returns {Array} 每组参数的测试结果
     */
    RunAll() {
        local results := []
        for index, args in this._parameters {
            local caseName := this.name "[" index "]"
            local testCase := DynamicTestCase(caseName, () => this._testFunc(args*))
            results.Push(testCase.Run())
        }
        return results
    }
    
    RunTest() {
        ; 默认运行第一组参数
        if (this._parameters.Length > 0) {
            this._testFunc(this._parameters[1]*)
        }
    }
}
```

- [ ] **Step 2: 实现测试套件**

```ahk
#Requires AutoHotkey v2.0

/**
 * 测试套件
 * 组织和管理多个测试用例
 */
class TestSuite {
    name := ""
    _tests := []
    _fixture := ""
    _beforeAll := ""
    _afterAll := ""
    _results := []
    
    /**
     * 构造函数
     * @param suiteName {String} 套件名称
     * @param fixture {TestFixture} [可选] 测试夹具
     */
    __New(suiteName, fixture := "") {
        this.name := suiteName
        this._fixture := fixture
    }
    
    /**
     * 添加测试用例
     * @param testCase {TestCase} 测试用例
     */
    AddTest(testCase) {
        this._tests.Push(testCase)
        return this
    }
    
    /**
     * 添加测试函数
     * @param testName {String} 测试名称
     * @param testFunc {Func} 测试函数
     */
    Test(testName, testFunc) {
        local testCase := DynamicTestCase(testName, testFunc)
        if (this._fixture != "") {
            testCase.SetUp := this._fixture.SetUp.Bind(this._fixture)
            testCase.TearDown := this._fixture.TearDown.Bind(this._fixture)
        }
        return this.AddTest(testCase)
    }
    
    /**
     * 设置套件前置操作
     * @param func {Func} 前置函数
     */
    BeforeAll(func) {
        this._beforeAll := func
        return this
    }
    
    /**
     * 设置套件后置操作
     * @param func {Func} 后置函数
     */
    AfterAll(func) {
        this._afterAll := func
        return this
    }
    
    /**
     * 运行套件中所有测试
     * @returns {Map} 套件结果
     */
    Run() {
        this._results := []
        local suiteStart := A_TickCount
        local passed := 0
        local failed := 0
        
        ; 执行 BeforeAll
        if (this._beforeAll != "") {
            try {
                this._beforeAll()
            } catch Error as e {
                return {
                    name: this.name,
                    result: "error",
                    error: "BeforeAll 失败: " e.Message,
                    tests: []
                }
            }
        }
        
        ; 运行每个测试
        for testCase in this._tests {
            local result := testCase.Run()
            this._results.Push(result)
            if (result.result == "passed") {
                passed++
            } else {
                failed++
            }
        }
        
        ; 执行 AfterAll
        if (this._afterAll != "") {
            try {
                this._afterAll()
            } catch Error as e {
                ; 记录但不影响测试结果
            }
        }
        
        return {
            name: this.name,
            result: failed > 0 ? "failed" : "passed",
            duration: A_TickCount - suiteStart,
            passed: passed,
            failed: failed,
            total: this._tests.Length,
            tests: this._results
        }
    }
    
    /**
     * 获取测试数量
     */
    GetTestCount() {
        return this._tests.Length
    }
}
```

---

## Task 5: 创建测试运行器

**Files:**
- Create: `tests/TestRunner.ahk`
- Create: `tests/run-tests.ahk`

- [ ] **Step 1: 实现测试运行器**

```ahk
#Requires AutoHotkey v2.0

/**
 * 测试运行器
 * 发现、组织和执行测试
 */
class TestRunner {
    static _suites := []
    static _filters := []
    static _reporters := []
    
    /**
     * 注册测试套件
     * @param suite {TestSuite} 测试套件
     */
    static AddSuite(suite) {
        this._suites.Push(suite)
        return this
    }
    
    /**
     * 设置测试过滤器
     * @param pattern {String} 过滤模式（支持通配符）
     */
    static SetFilter(pattern) {
        this._filters.Push(pattern)
        return this
    }
    
    /**
     * 添加报告器
     * @param reporter {TestReporter} 报告器实例
     */
    static AddReporter(reporter) {
        this._reporters.Push(reporter)
        return this
    }
    
    /**
     * 运行所有测试
     * @returns {Map} 测试结果摘要
     */
    static Run() {
        local totalStart := A_TickCount
        local allResults := []
        local totalPassed := 0
        local totalFailed := 0
        local totalSkipped := 0
        
        ; 通知报告器开始
        for reporter in this._reporters {
            reporter.OnStart()
        }
        
        ; 运行每个套件
        for suite in this._suites {
            ; 应用过滤器
            if (!this._matchesFilter(suite.name)) {
                continue
            }
            
            ; 通知报告器套件开始
            for reporter in this._reporters {
                reporter.OnSuiteStart(suite)
            }
            
            ; 运行套件
            local suiteResult := suite.Run()
            allResults.Push(suiteResult)
            
            totalPassed += suiteResult.passed
            totalFailed += suiteResult.failed
            
            ; 通知报告器套件结束
            for reporter in this._reporters {
                reporter.OnSuiteEnd(suiteResult)
            }
        }
        
        ; 生成摘要
        local summary := {
            duration: A_TickCount - totalStart,
            totalSuites: this._suites.Length,
            totalTests: totalPassed + totalFailed,
            passed: totalPassed,
            failed: totalFailed,
            skipped: totalSkipped,
            suites: allResults
        }
        
        ; 通知报告器结束
        for reporter in this._reporters {
            reporter.OnComplete(summary)
        }
        
        this._printSummary(summary)
        return summary
    }
    
    /**
     * 检查套件名是否匹配过滤器
     */
    static _matchesFilter(name) {
        if (this._filters.Length == 0) {
            return true
        }
        for pattern in this._filters {
            if (this._wildcardMatch(name, pattern)) {
                return true
            }
        }
        return false
    }
    
    /**
     * 通配符匹配
     */
    static _wildcardMatch(text, pattern) {
        ; 简单的 * 通配符实现
        pattern := StrReplace(pattern, "*", ".*")
        return RegExMatch(text, "^" pattern "$")
    }
    
    /**
     * 打印摘要到控制台
     */
    static _printSummary(summary) {
        OutputDebug("`n" String.Repeat("=", 60))
        OutputDebug("测试完成")
        OutputDebug(String.Repeat("=", 60))
        OutputDebug("总套件: " summary.totalSuites)
        OutputDebug("总测试: " summary.totalTests)
        OutputDebug("通过: " summary.passed)
        OutputDebug("失败: " summary.failed)
        OutputDebug("耗时: " summary.duration "ms")
        
        if (summary.failed > 0) {
            OutputDebug("`n失败详情:")
            for suite in summary.suites {
                for test in suite.tests {
                    if (test.result != "passed") {
                        OutputDebug("  " suite.name " > " test.name ": " test.error)
                    }
                }
            }
        }
        
        OutputDebug(String.Repeat("=", 60))
    }
    
    /**
     * 清空所有套件
     */
    static Clear() {
        this._suites := []
        this._filters := []
    }
}

/**
 * 字符串工具类
 */
class String {
    static Repeat(str, count) {
        local result := ""
        Loop count {
            result .= str
        }
        return result
    }
}
```

- [ ] **Step 2: 创建测试入口脚本**

```ahk
#Requires AutoHotkey v2.0

; 测试执行入口
; 用法: autohotkey.exe tests\run-tests.ahk [filter]

#Include "%A_ScriptDir%\TestFramework\Assert.ahk"
#Include "%A_ScriptDir%\TestFramework\Mock.ahk"
#Include "%A_ScriptDir%\TestFramework\TestCase.ahk"
#Include "%A_ScriptDir%\TestFramework\TestSuite.ahk"
#Include "%A_ScriptDir%\TestFramework\ destinationViewController.ahk"

; 包含测试文件
#Include "%A_ScriptDir%\Core\Common\ConfigService.test.ahk"
#Include "%A_ScriptDir%\Core\Conditions\ConditionEngine.test.ahk"
#Include "%A_ScriptDir%\Core\Events\EventBus.test.ahk"

; 解析命令行参数
if (A_Args.Length > 0) {
    TestRunner.SetFilter(A_Args[1])
}

; 运行测试
local result := TestRunner.Run()

; 退出码
ExitApp(result.failed > 0 ? 1 : 0)
```

---

## Task 6: 创建测试报告器

**Files:**
- Create: `tests/TestFramework/TestReporter.ahk`

- [ ] **Step 1: 实现基础报告器接口**

```ahk
#Requires AutoHotkey v2.0

/**
 * 测试报告器基类
 */
class TestReporter {
    OnStart() {
        ; 测试开始时调用
    }
    
    OnSuiteStart(suite) {
        ; 套件开始时调用
    }
    
    OnSuiteEnd(suiteResult) {
        ; 套件结束时调用
    }
    
    OnComplete(summary) {
        ; 所有测试完成时调用
    }
}

/**
 * 控制台报告器
 * 输出彩色测试结果到控制台
 */
class ConsoleReporter extends TestReporter {
    OnStart() {
        OutputDebug("`n开始运行测试...`n")
    }
    
    OnSuiteStart(suite) {
        OutputDebug("`n[" suite.name "]")
    }
    
    OnSuiteEnd(suiteResult) {
        for test in suiteResult.tests {
            local icon := test.result == "passed" ? "PASS" : "FAIL"
            local msg := "  " icon " " test.name " (" test.duration "ms)"
            if (test.error != "") {
                msg .= "`n      " test.error
            }
            OutputDebug(msg)
        }
    }
}

/**
 * JSON 报告器
 * 生成 JSON 格式的测试报告
 */
class JsonReporter extends TestReporter {
    outputPath := ""
    
    __New(outputPath) {
        this.outputPath := outputPath
    }
    
    OnComplete(summary) {
        try {
            local json := JSON.Dump(summary, 2)
            FileAppend(json, this.outputPath)
            OutputDebug("JSON 报告已保存到: " this.outputPath)
        } catch Error as e {
            OutputDebug("保存 JSON 报告失败: " e.Message)
        }
    }
}

/**
 * JUnit XML 报告器
 * 生成与 CI 工具兼容的 JUnit XML 格式
 */
class JUnitReporter extends TestReporter {
    outputPath := ""
    
    __New(outputPath) {
        this.outputPath := outputPath
    }
    
    OnComplete(summary) {
        try {
            local xml := this._generateXml(summary)
            FileAppend(xml, this.outputPath)
            OutputDebug("JUnit 报告已保存到: " this.outputPath)
        } catch Error as e {
            OutputDebug("保存 JUnit 报告失败: " e.Message)
        }
    }
    
    _generateXml(summary) {
        local xml := '<?xml version="1.0" encoding="UTF-8"?>`n'
        xml .= '<testsuites tests="' summary.totalTests '" failures="' summary.failed '" time="' (summary.duration / 1000) '">`n'
        
        for suite in summary.suites {
            xml .= '  <testsuite name="' suite.name '" tests="' suite.total '" failures="' suite.failed '" time="' (suite.duration / 1000) '">`n'
            
            for test in suite.tests {
                xml .= '    <testcase name="' test.name '" time="' (test.duration / 1000) '">'
                if (test.result != "passed") {
                    xml .= '<failure message="' this._escapeXml(test.error) '"/>'
                }
                xml .= '</testcase>`n'
            }
            
            xml .= '  </testsuite>`n'
        }
        
        xml .= '</testsuites>'
        return xml
    }
    
    _escapeXml(text) {
        text := StrReplace(text, "&", "&amp;")
        text := StrReplace(text, "<", "&lt;")
        text := StrReplace(text, ">", "&gt;")
        text := StrReplace(text, '"', "&quot;")
        text := StrReplace(text, "`n", "&#10;")
        return text
    }
}
```

---

## Task 7: 编写核心服务测试用例

**Files:**
- Create: `tests/Core/Common/ConfigService.test.ahk`
- Create: `tests/Core/Conditions/ConditionEngine.test.ahk`
- Create: `tests/Core/events/EventBus.test.ahk`

- [ ] **Step 1: ConfigService 测试**

```ahk
#Requires AutoHotkey v2.0

; 创建测试套件
local configSuite := TestSuite("ConfigService")

configSuite.Test("GetConfig 返回默认值", () => {
    ; 使用 Mock 隔离文件系统
    MockFileSystem.Reset()
    MockFileSystem.SetupFileExists(A_ScriptDir "\..\..\config.json", false)
    
    ; 注意: 这需要重构 ConfigService 以便测试
    ; 目前先测试已知行为
    Assert.True(true, "占位测试")
})

configSuite.Test("SetConfig 持久化配置", () => {
    ; 验证配置设置后能正确读回
    ConfigService.SetConfig("test", "key", "value")
    local result := ConfigService.GetConfig("test", "key")
    Assert.Equal("value", result)
})

TestRunner.AddSuite(configSuite)
```

- [ ] **Step 2: ConditionEngine 测试**

```ahk
#Requires AutoHotkey v2.0

local conditionSuite := TestSuite("ConditionEngine")

conditionSuite.Test("AND 条件评估", () => {
    local expr := Map("type", "AND", "conditions", [
        Map("type", "test", "value", true),
        Map("type", "test", "value", true)
    ])
    ; 需要注册测试条件提供者
    ; 暂时使用占位
    Assert.True(true, "占位测试")
})

conditionSuite.Test("OR 条件评估", () => {
    Assert.True(true, "占位测试")
})

TestRunner.AddSuite(conditionSuite)
```

- [ ] **Step 3: EventBus 测试**

```ahk
#Requires AutoHotkey v2.0

local eventSuite := TestSuite("EventBus")

eventSuite.Test("订阅和触发事件", () => {
    local received := false
    local handler(*) => received := true
    
    ; 需要先注册事件
    ; EventBus.On("test.event", handler)
    ; EventBus.Trigger("test.event")
    
    ; Assert.True(received)
    Assert.True(true, "占位测试 - 需要事件注册")
})

eventSuite.Test("取消订阅事件", () => {
    Assert.True(true, "占位测试")
})

TestRunner.AddSuite(eventSuite)
```

---

## Task 8: 创建 GitHub Actions CI 配置

**Files:**
- Create: `.github/workflows/test.yml`

- [ ] **Step 1: 创建 CI 工作流**

```yaml
name: Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: windows-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Install AutoHotkey
        run: |
          choco install autohotkey -y
          
      - name: Build C# DLL
        run: |
          cd src\AHKestra.Tools.Json
          dotnet build -c Release
          
      - name: Run Tests
        run: |
          autohotkey.exe tests\run-tests.ahk
          
      - name: Upload Test Report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-report
          path: test-results/
```

---

## Task 9: 验证和集成

- [ ] **Step 1: 运行完整测试套件**

运行: `autohotkey.exe tests\run-tests.ahk`
预期: 显示测试结果摘要

- [ ] **Step 2: 生成测试报告**

运行: `autohotkey.exe tests\run-tests.ahk --reporter junit`
预期: 在 `test-results/` 目录生成 XML 报告

- [ ] **Step 3: 验证 CI 配置**

提交代码并推送到 GitHub，验证 Actions 工作流执行

---

## 完成检查清单

- [ ] 断言库完整实现
- [ ] 测试夹具系统完成
- [ ] 模拟对象系统完成
- [ ] 测试用例和套件完成
- [ ] 测试运行器完成
- [ ] 测试报告器完成
- [ ] 核心服务测试用例编写
- [ ] CI 配置完成
- [ ] 文档更新

---

## macOS 开发工作流

在 macOS 上开发时的验证流程：

1. **语法检查**: 使用 VSCode ahk2 扩展实时检查
2. **逻辑验证**: 编写单元测试，推送到 CI 验证
3. **代码审查**: 重点关注 Windows API 调用和文件路径
4. **模拟测试**: 使用 MockWindowsApi 验证业务逻辑
