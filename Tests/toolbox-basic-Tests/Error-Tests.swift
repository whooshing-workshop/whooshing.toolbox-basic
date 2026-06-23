import Testing
import Foundation
@testable import ErrorHandle

// MARK: - 测试内容

@Suite("错误处理模块-测试")
struct ErrorTests {

    static let explain = "test explain"
    static let datas = (0..<2).map { _ in String(UUID().uuidString.prefix(6)) }
    static let err = B.error3

    static let explain2 = "test explain 2"
    static let datas2 = (0..<2).map { _ in Int.random(in: 100...300) }
    static let err2 = A.error1

    static let subErr = A.error2.d(category: .internal).adds([1, 2])

    let err2 = Self.err2.d(Self.explain2, category: .internal).adds(Self.datas2)

    @Test("测试 ErrListWithOptionAddition 扩展的参数传递") func testErrListWithOptionAddition() {
        let error = Self.err.d(Self.explain, category: .internal).adds(Self.datas)
        #expect(error.error.rawValue == B.error3.rawValue)
        #expect(error.explain == Self.explain)
        #expect(error.a1 == Self.datas[0])
        #expect(error.a2 == Self.datas[1])
        #expect(error.file == #fileID)
        #expect(error.line == 23)
    }

    @Test("测试 ErrListWithIndeedAddition 扩展的参数传递") func testErrListWithIndeedAddition() {
        #expect(err2.error.rawValue == A.error1.rawValue)
        #expect(err2.explain == Self.explain2)
        #expect(err2.a1 == Self.datas2[0])
        #expect(err2.a2 == Self.datas2[1])
        #expect(err2.file == #fileID)
        #expect(err2.line == 20)
    }

    let explains = [0, 1, 1, 0, 1, 0]
    let marks = [0, 0, 0, 1, 1, 1]
    let lineStart = 50

    @Test("测试所有方法的参数传递", arguments: [
        0: Self.err.d(category: .internal),
        1: Self.err.d(Self.explain, category: .internal),
        2: Self.err.d(Self.explain, category: .internal),
    ])
    func testFuncs(i: Int, e: CustomError2) {
        #expect(explains[i] == 0 ? e.explain == nil : e.explain == Self.explain)
        #expect(e.a1 == "Unset a1")
        #expect(e.a2 == "Unset a2")
        #expect(e.file == #fileID)
        #expect(e.line == lineStart)
    }

    @Test("测试 Err.subErr() 函数") func testSubError() async throws {
        #expect(Self.err.d(category: .internal).subErr(Self.subErr).subError as? A.ErrType == Self.subErr)
    }

    @Test("测试 required 以及 == 函数") func testRequiredFunction() {
        do {
            let _ = try required(
                throws: B.error3.d(category: .internal)
            ) {
                throw A.error1.d(category: .internal).adds([1, 2, 3])
            }
            #expect(Bool(false))
        } catch let err {
            #expect(err.line == 65)
            #expect(err.error.rawValue == B.error3.rawValue)
            #expect(err.subError as! A.ErrType != A.error1.d(category: .internal, file: #fileID, line: #line).adds([1, 2, 3]))
            #expect(err.subError as! A.ErrType == A.error1.d(category: .internal, file: #fileID, line: 67).adds([1, 2, 3]))
            #expect((err.subError as! A.ErrType).isSameType(of: A.error1.d(category: .internal, file: "Test", line: 90).adds([0, 0])))
        }
    }
    
    @Test("测试 RawError")
    func rawErrorTest() async throws {
        let err = ErrorTypes1.error1.d("Testing", category: .internal)
        #expect(err.error.identifier == "ErrorTypes1.error1")
    }
    
    @Test("测试 ErrorCategory")
    func errorCategoryTest() async throws {
        let err = ErrorTypes1.error1.d("Testing", category: .external(suggestions: ["suggestion 1", "suggestion 2"]))
        #expect(err.description.contains("error1-external(suggestion 1 | suggestion 2)"))
    }
}

// MARK: - 类型定义

enum ErrorTypes1: String, ErrList {
    typealias ErrType = CustomError1
    case error1
    case error2
}

struct CustomError1: Err {
    typealias AdditionType = [Int]
    var error: ErrorTypes1!
    var category: ErrCategory!
    var explain: String?
    var file: String!
    var line: Int!
    var function: String!
    var subError: Error?
    var metadata: Logger.Metadata?

    var a1: Int!
    var a2: Int!

    init(category: ErrCategory) { self.category = category }
    
    mutating func initAdds(_ addtion: [Int]) {
        a1 = addtion[0]
        a2 = addtion[1]
    }
}

typealias A = ErrorTypes1

enum ErrorTypes2: String, ErrList {
    typealias ErrType = CustomError2
    case error3 = "Error 3 summary"
    case error4 = "Error 4 summary"
}

struct CustomError2: Err {
    typealias AdditionType = [String]?
    var error: ErrorTypes2!
    var category: ErrCategory!
    var explain: String?
    var file: String!
    var line: Int!
    var function: String!
    var subError: Error?
    var metadata: Logger.Metadata?

    var a1: String = "Unset a1"
    var a2: String = "Unset a2"

    init(category: ErrCategory) { self.category = category }
    
    mutating func initAdds(_ addtion: [String]?) {
        if let d = addtion {
            a1 = d[0]
            a2 = d[1]
        } else {
            a1 = "Unset a1"
            a2 = "Unset a2"
        }
    }
}

typealias B = ErrorTypes2
