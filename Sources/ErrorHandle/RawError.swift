/// 错误类别协议，所有错误类别枚举必须遵循该协议。
/// 每个错误类别必须具有原始值（通常为字符串），并支持遍历与并发安全。
public protocol ErrCategory: RawRepresentable, CaseIterable, Sendable {}

/// 系统的基础错误类别枚举。
/// - parameter: 表示提供给函数或接口的参数无效。
/// - internel: 表示系统在处理过程中出现了内部错误。
public enum BscErrCategory: String, ErrCategory {
    case parameter = "提供的参数错误"
    case internel = "内部错误"
}

/// 通用错误协议，用于定义带有类别和摘要信息的错误类型。
/// 任意遵循该协议的类型都必须提供错误摘要、错误类别，并能以原始值形式表达自身。
/// 适用于所有需要结构化错误信息的场景。
public protocol RawError: RawRepresentable, CustomStringConvertible, Sendable {
    associatedtype Category: ErrCategory = BscErrCategory
    associatedtype SummaryType = String
    /// 错误的简要文本描述，用于表示该错误的核心含义。
    var summary: SummaryType { get }
    /// 错误所属的类别，用于对错误进行分组与分类管理。
    var category: Category { get }
    
    /// 初始化错误实例。
    /// - Parameters:
    ///   - summary: 错误的简短描述。
    ///   - category: 错误所属的类别。
    /// 使用该构造函数可生成一个完整的错误对象。
    init(_ summary: SummaryType, _ category: Category)
}

public extension RawError {
    var description: String { "\(rawValue)" }
    init?(rawValue: RawValue) { nil }
}

public typealias BscRawError = RawErrorBase<String>

/// 基础错误实现，符合 RawError 协议。
/// 用于构造标准化的错误对象，并提供格式化的原始值表示。
/// 原始值由类别说明与错误摘要拼接构成。
public struct RawErrorBase<SummaryType: Sendable>: RawError {
    /// 完整的错误字符串表示，由类别前缀与摘要组成。
    public let rawValue: String
    /// 错误的核心描述内容。
    public let summary: SummaryType
    /// 错误所属的类别，用于分类与区分不同类型的错误。
    public let category: Category
    
    /// 创建一个基础错误对象。
    /// - Parameters:
    ///   - summary: 错误的简要描述。
    ///   - category: 错误的类别。
    /// 初始化后将自动生成格式化的 rawValue 字符串。
    public init(_ summary: SummaryType, _ category: Category) {
        self.summary = summary
        self.category = category
        self.rawValue = "[\(category.rawValue)]\(summary)"
    }
}
