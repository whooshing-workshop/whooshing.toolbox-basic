import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ErrorListMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let _ = declaration.as(EnumDeclSyntax.self) else {
            fatalError("编译错误：该宏只能用于 Enum")
        }
        
        let res: DeclSyntax = """
        extension \(type.trimmed): ErrList {}
        """
        
        guard let extensionDecl = res.as(ExtensionDeclSyntax.self) else {
            fatalError("编译错误：无法生成 extension")
        }

        return [extensionDecl]
    }
}

public struct ModeMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let _ = node.arguments?.as(LabeledExprListSyntax.self) else {
            fatalError("编译错误: 应当提供宏参数")
        }
        
        guard let _ = declaration.as(EnumCaseDeclSyntax.self) else {
            fatalError("编译错误：该宏只能用于 Enum Cases")
        }
        
        return []
    }
}

public struct ErrorBuilderMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let a = node.arguments?.as(LabeledExprListSyntax.self) else {
            fatalError("编译错误: 应当提供宏参数")
        }
        
        guard let e = declaration.as(EnumDeclSyntax.self) else {
            fatalError("编译错误：该宏只能用于 Enum")
        }
        
        var res: [DeclSyntax] = []
        
        let argus = Array(a)
        
        res.append(contentsOf: argus.count > 0 ?
            argus[0].expression.is(NilLiteralExprSyntax.self) ?
                [] :
                ["typealias ErrType = \(raw: sts(argus[0].expression))"] :
            []
        )
        
        let rawErrorType: String
        
        if argus.count > 1 {
            rawErrorType = String(argus[1].trimmedDescription.dropLast(".self".count))
        } else if let enumRawType = declaration.inheritanceClause?.inheritedTypes.first?.trimmedDescription {
            rawErrorType = isRawType(enumRawType) ? "RawErrorBase<\(enumRawType)>" : "BscRawError"
        } else {
            rawErrorType = "BscRawError"
        }
        
        var switchCases: [String] = []
        
        for member in e.memberBlock.members {
            guard
                let ec = member.decl.as(EnumCaseDeclSyntax.self),
                let a = ec.attributes.first?.as(AttributeSyntax.self),
                let b = a.arguments?.as(LabeledExprListSyntax.self)
            else {
                break
            }
            
            let args = Array(b)
            let rawCategory = sts(args[0].expression)
            
            let element = Array(ec.elements)[0]
            
            let key = element.name
            let summary = element.rawValue?.value ?? .init(literal: key.description)
            
            switchCases.append("""
            case .\(key): .init(\(summary), .\(rawCategory))
            """)
        }
        
        res.append("""
            var rawValue: \(raw: rawErrorType) {
                switch self {
                \(raw: switchCases.joined(separator: "\n"))
                }
            }
            """)
        
        return res
    }
}

func sts(_ s: SwiftSyntax.ExprSyntax) -> String {
    guard let a = s.as(StringLiteralExprSyntax.self) else {
        fatalError("编译错误：提供的参数并非是字符串")
    }
    return a.segments.description
}

func isRawType(_ s: String) -> Bool {
    let intTypes: Set<String> = ["Int", "Int8", "Int16", "Int32", "Int64",
                                 "UInt", "UInt8", "UInt16", "UInt32", "UInt64"]
    let floatTypes: Set<String> = ["Float", "Double"]
    let otherTypes: Set<String> = ["String", "Bool", "Character"]
    
    return intTypes.contains(s) || floatTypes.contains(s) || otherTypes.contains(s)
}

@main
struct MyMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ModeMacro.self,
        ErrorListMacro.self,
        ErrorBuilderMacro.self
    ]
}
