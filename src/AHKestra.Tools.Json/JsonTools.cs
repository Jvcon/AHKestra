using System.Runtime.InteropServices;
using System.Text.Json;
using NJsonSchema;
using RGiesecke.DllExport;

// 命名空间与 .csproj 文件中定义的 <RootNamespace> 一致
namespace AHKestra
{
    /// <summary>
    /// 用于封装验证结果的记录类型。
    /// 将被序列化为 JSON 字符串返回给 AutoHotkey。
    /// </summary>
    public record ValidationResult
    {
        public bool IsValid { get; init; }
        public List<ErrorDetail> Errors { get; init; } = new();
    }

    /// <summary>
    /// 用于封装单个验证错误的详细信息。
    /// </summary>
    public record ErrorDetail
    {
        // JSON 节点路径，例如 "properties.name"
        public string Path { get; init; } = string.Empty;

        // 错误类型，例如 "StringExpected"
        public string Kind { get; init; } = string.Empty;
        
        // 错误的具体描述
        public string Description { get; init; } = string.Empty;
    }

    public static class JsonTools
    {
        [DllExport("ValidateManifest", CallingConvention = CallingConvention.StdCall)]
        [return: MarshalAs(UnmanagedType.LPWStr)]
        public static string ValidateManifest(
            [MarshalAs(UnmanagedType.LPWStr)] string schemaJson,
            [MarshalAs(UnmanagedType.LPWStr)] string manifestJson)
        {
            try
            {
                // 从字符串异步加载 Schema，并同步等待结果
                // 正如多个文档提到的，库的核心功能是从文件或字符串读取 Schema
                // [RicoSuter/NJsonSchema: JSON Schema reader, generator ... - GitHub](https://github.com/RicoSuter/NJsonSchema){target="_blank" class="gpt-web-url"}
                var schema = JsonSchema.FromJsonAsync(schemaJson).Result;

                // 使用加载的 Schema 验证 JSON 数据
                // Validate 方法会返回一个包含所有验证错误的集合
                // [How to validate json with json schema in NJsonSchema c# - Stack ...](https://stackoverflow.com/questions/50524325/how-to-validate-json-with-json-schema-in-njsonschema-c-sharp){target="_blank" class="gpt-web-url"}
                var validationErrors = schema.Validate(manifestJson);

                ValidationResult result;
                if (validationErrors.Count == 0)
                {
                    // 如果没有错误，创建一个表示成功的返回对象
                    result = new ValidationResult { IsValid = true };
                }
                else
                {
                    // 如果存在错误，创建一个表示失败的返回对象，并填充详细错误信息
                    // 我们可以从 ValidationError 对象中提取丰富的信息，如路径和错误类型
                    // [Detailed validation error information](https://www.newtonsoft.com/jsonschema/help/html/JTokenIsValidWithValidationErrors.htm){target="_blank" class="gpt-web-url"}
                    result = new ValidationResult
                    {
                        IsValid = false,
                        Errors = validationErrors.Select(err => new ErrorDetail
                        {
                            Path = err.Path,
                            Kind = err.Kind.ToString(),
                            Description = err.ToString() // err.ToString() 提供了格式化的错误消息
                        }).ToList()
                    };
                }

                // 将结构化的结果对象序列化为 JSON 字符串后返回
                return JsonSerializer.Serialize(result);
            }
            catch (Exception ex)
            {
                // 如果在解析 Schema 或验证过程中出现异常，捕获并返回一个包含异常信息的错误对象
                var errorResult = new ValidationResult
                {
                    IsValid = false,
                    Errors = new List<ErrorDetail>
                    {
                        new ErrorDetail { Path = "System", Kind = "Exception", Description = ex.Message }
                    }
                };
                return JsonSerializer.Serialize(errorResult);
            }
        }
         [DllExport("ValidateManifestFromFile", CallingConvention = CallingConvention.StdCall)]
        [return: MarshalAs(UnmanagedType.LPWStr)]
        public static string ValidateManifestFromFile(
            [MarshalAs(UnmanagedType.LPWStr)] string schemaPath,
            [MarshalAs(UnmanagedType.LPWStr)] string manifestPath)
        {
            try
            {
                // 使用 NJsonSchema 的内置方法直接从文件加载 Schema。
                // 这比手动 File.ReadAllText 更为直接和优雅。
                // 正如官方仓库文档所说，库支持从文件读取。
                // [RicoSuter/NJsonSchema: JSON Schema reader, generator ... - GitHub](https://github.com/RicoSuter/NJsonSchema){target="_blank" class="gpt-web-url"}
                var schema = JsonSchema.FromFileAsync(schemaPath).Result;

                // 读取 manifest 文件的内容为字符串。
                // 多个教程和示例都展示了这种标准的文件读取方式。
                // [How to C#: Validating a JSON to a JSON Schema - DEV Community](https://dev.to/iamrule/how-to-c-validating-a-json-to-a-json-schema-3mle){target="_blank" class="gpt-web-url"}
                string manifestJson = File.ReadAllText(manifestPath);

                // 后续的验证逻辑与原函数完全相同
                var validationErrors = schema.Validate(manifestJson);

                ValidationResult result;
                if (validationErrors.Count == 0)
                {
                    result = new ValidationResult { IsValid = true };
                }
                else
                {
                    result = new ValidationResult
                    {
                        IsValid = false,
                        Errors = validationErrors.Select(err => new ErrorDetail
                        {
                            Path = err.Path,
                            Kind = err.Kind.ToString(),
                            Description = err.ToString()
                        }).ToList()
                    };
                }
                return JsonSerializer.Serialize(result);
            }
            catch (Exception ex)
            {
                // 捕获所有异常，包括文件未找到、读取错误、JSON 解析错误等
                var errorResult = new ValidationResult
                {
                    IsValid = false,
                    Errors = new List<ErrorDetail>
                    {
                        // 提供更具体的错误类型，有助于调试
                        new ErrorDetail { Path = "System.IO", Kind = ex.GetType().Name, Description = ex.Message }
                    }
                };
                return JsonSerializer.Serialize(errorResult);
            }
        }
    }
}
