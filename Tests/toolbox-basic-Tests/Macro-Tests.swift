import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MacrosImplements)
import MacrosImplements
import Macros

let testMacros: [String: Macro.Type] = [
    "Mode": ModeMacro.self,
    "ErrorList": ErrorListMacro.self,
    "ErrorBuilder": ErrorBuilderMacro.self
]
#endif

import ErrorHandle

enum ErrorTyped: ErrList {
    case error1
    case error2
    
    var rawValue: BscRawError {
        switch self {
        case .error1: .init("Error 1 summary", .internel)
        case .error2: .init("Error 2 summary", .internel)
        }
    }
}

@ErrorList()
@ErrorBuilder()
enum ErrorTypeTesting: Float {
    @Mode("internel") case error1 = 1.3
    @Mode("internel") case error2 = 1.5
}

final class MacroTests: XCTestCase {
    func testMacro1() throws {
        #if canImport(MacrosImplements)
        assertMacroExpansion(
            """
            @ErrorList()
            @ErrorBuilder()
            enum ErrorTypeTesting: String {
                @Mode("internel") case error1 = "Error 1 summary"
                @Mode("internel") case error2 = "Error 2 summary"
            }
            """,
            expandedSource: """
            enum ErrorTypeTesting: String {
                case error1 = "Error 1 summary"
                case error2 = "Error 2 summary"

                var rawValue: RawErrorBase<String> {
                    switch self {
                    case .error1 :
                        .init("Error 1 summary", .internel)
                    case .error2 :
                        .init("Error 2 summary", .internel)
                    }
                }
            }

            extension ErrorTypeTesting: ErrList {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacro2() throws {
        #if canImport(MacrosImplements)
        assertMacroExpansion(
            """
            @ErrorList()
            @ErrorBuilder(nil, BscRawError.self)
            enum ErrorTypeTesting: String {
                @Mode("internel") case error1 = "Error 1 summary"
                @Mode("internel") case error2 = "Error 2 summary"
            }
            """,
            expandedSource: """
            enum ErrorTypeTesting: String {
                case error1 = "Error 1 summary"
                case error2 = "Error 2 summary"

                var rawValue: BscRawError {
                    switch self {
                    case .error1 :
                        .init("Error 1 summary", .internel)
                    case .error2 :
                        .init("Error 2 summary", .internel)
                    }
                }
            }

            extension ErrorTypeTesting: ErrList {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testMacro3() throws {
        #if canImport(MacrosImplements)
        assertMacroExpansion(
            """
            @ErrorList()
            @ErrorBuilder("XXX", RawError<Any>.self)
            enum ErrorTypeTesting: String {
                @Mode("internel") case error1 = "Error 1 summary"
                @Mode("internel") case error2 = "Error 2 summary"
            }
            """,
            expandedSource: """
            enum ErrorTypeTesting: String {
                case error1 = "Error 1 summary"
                case error2 = "Error 2 summary"
            
                typealias ErrType = XXX

                var rawValue: RawError<Any> {
                    switch self {
                    case .error1 :
                        .init("Error 1 summary", .internel)
                    case .error2 :
                        .init("Error 2 summary", .internel)
                    }
                }
            }

            extension ErrorTypeTesting: ErrList {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testMacro4() throws {
        #if canImport(MacrosImplements)
        assertMacroExpansion(
            """
            @ErrorList()
            @ErrorBuilder()
            enum ErrorTypeTesting: String {}
            """,
            expandedSource: """
            enum ErrorTypeTesting: String {

                var rawValue: RawErrorBase<String> {
                    switch self {

                    }
                }
            }

            extension ErrorTypeTesting: ErrList {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testMacro5() throws {
        #if canImport(MacrosImplements)
        assertMacroExpansion(
            """
            @ErrorList()
            @ErrorBuilder()
            enum ErrorTypeTesting: String {
                @Mode("internel") case error1 = "Error 1 summary"
                @Mode("internel") case error2 = "Error 2 summary"
            
                typealias ErrType = XXX
            }
            """,
            expandedSource: """
            enum ErrorTypeTesting: String {
                case error1 = "Error 1 summary"
                case error2 = "Error 2 summary"
            
                typealias ErrType = XXX

                var rawValue: RawErrorBase<String> {
                    switch self {
                    case .error1 :
                        .init("Error 1 summary", .internel)
                    case .error2 :
                        .init("Error 2 summary", .internel)
                    }
                }
            }

            extension ErrorTypeTesting: ErrList {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testMacro6() throws {
        #if canImport(MacrosImplements)
        assertMacroExpansion(
            """
            @ErrorList()
            @ErrorBuilder()
            enum ErrorTypeTesting {
                @Mode("internel") case error1
                @Mode("internel") case error2
            }
            """,
            expandedSource: """
            enum ErrorTypeTesting {
                case error1
                case error2

                var rawValue: BscRawError {
                    switch self {
                    case .error1:
                        .init("error1", .internel)
                    case .error2:
                        .init("error2", .internel)
                    }
                }
            }

            extension ErrorTypeTesting: ErrList {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testMacro7() throws {
        #if canImport(MacrosImplements)
        assertMacroExpansion(
            """
            @ErrorList()
            @ErrorBuilder()
            enum ErrorTypeTesting: Float {
                @Mode("internel") case error1 = 1.3
                @Mode("internel") case error2 = 1.5
            }
            """,
            expandedSource: """
            enum ErrorTypeTesting: Float {
                case error1 = 1.3
                case error2 = 1.5

                var rawValue: RawErrorBase<Float> {
                    switch self {
                    case .error1 :
                        .init(1.3, .internel)
                    case .error2 :
                        .init(1.5, .internel)
                    }
                }
            }

            extension ErrorTypeTesting: ErrList {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testMacro8() throws {
        #if canImport(MacrosImplements)
        assertMacroExpansion(
            """
            @ErrorList()
            @ErrorBuilder()
            enum ErrorTypeTesting: XXXXX {
                @Mode("internel") case error1 = "1.3"
                @Mode("internel") case error2 = "1.5"
            }
            """,
            expandedSource: """
            enum ErrorTypeTesting: XXXXX {
                case error1 = "1.3"
                case error2 = "1.5"

                var rawValue: BscRawError {
                    switch self {
                    case .error1 :
                        .init("1.3", .internel)
                    case .error2 :
                        .init("1.5", .internel)
                    }
                }
            }

            extension ErrorTypeTesting: ErrList {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
