import Testing
@testable import ToolboxBsc
import Foundation

// MARK: - 测试内容

@Suite("错误处理模块-测试")
struct ErrorTests {

    static let explain = "test explain"
    static let mark = Int.random(in: 1..<100)
    static let datas = (0..<2).map { _ in String(UUID().uuidString.prefix(6)) }
    static let err = B.error3

    @Test("测试 ErrListWithOptionAddition 扩展的参数传递") func testErrListWithOptionAddition() {
        let error = Self.err.d(Self.explain, Self.mark, Self.datas, (#file, #line))
        #expect(error.summary == B.error3.rawValue)
        #expect(error.explain == Self.explain)
        #expect(error.mark == Self.mark)
        #expect(error.a1 == Self.datas[0])
        #expect(error.a2 == Self.datas[1])
        #expect(error.file == #file)
        #expect(error.line == 16)
    }

    @Test("测试 ErrListWithIndeedAddition 扩展的参数传递") func testErrListWithIndeedAddition() {
        let explain = "Explain 1"
        let mark = 1
        let datas = [3, 4, 5]
        let error = A.error1.d(explain, mark, datas, (#file, #line))
        #expect(error.summary == A.error1.rawValue)
        #expect(error.explain == explain)
        #expect(error.mark == mark)
        #expect(error.a1 == datas[0])
        #expect(error.a2 == datas[1])
        #expect(error.file == #file)
        #expect(error.line == 30)
    }

    let explains = [0, 1, 1, 0, 0, 1, 1, 0, 0]
    let marks = [0, 0, 0, 1, 1, 1, 1, 0, 1]
    let datass = [0, 0, 0, 0, 1, 1, 0, 1, 1]
    let lineStart = 56

    @Test("测试所有方法的参数传递", arguments: [
        0: Self.err.d(#file, #line),
        1: Self.err.d(Self.explain, #file, #line),
        2: Self.err.d(Self.explain, (#file, #line)),
        3: Self.err.d(Self.mark, #file, #line),
        4: Self.err.d(Self.mark, Self.datas, #file, #line),
        5: Self.err.d(Self.explain, Self.mark, Self.datas, (#file, #line)),
        6: Self.err.d(Self.explain, Self.mark, (#file, #line)),
        7: Self.err.d(Self.datas ,#file, #line),
        8: Self.err.d(Self.mark, Self.datas, #file, #line),
    ])
    func testFuncs(i: Int, e: CustomError2) {
        #expect(explains[i] == 0 ? e.explain == nil : e.explain == Self.explain)
        #expect(marks[i] == 0 ? e.mark == nil : e.mark == Self.mark)
        #expect(datass[i] == 0 ? e.a1 == "Unset a1" : e.a1 == Self.datas[0])
        #expect(datass[i] == 0 ? e.a2 == "Unset a2" : e.a2 == Self.datas[1])
        #expect(e.file == #file)
        #expect(e.line == lineStart)
    }
}

// MARK: - 类型定义

enum ErrorTypes1: String, ErrListWithIndeedAddition {
    typealias ErrType = CustomError1
    case error1 = "Error 1 summary"
    case error2 = "Error 2 summary"
}

struct CustomError1: Err {
    typealias AdditionType = [Int]
    var summary: String!
    var explain: String?
    var file: String!
    var line: Int!
    var mark: Int?

    var a1: Int!
    var a2: Int!

    mutating func initAddtions(_ data: [Int]) {
        self.a1 = data[0]
        self.a2 = data[1]
    }
}

typealias A = ErrorTypes1

enum ErrorTypes2: String, ErrListWithOptionAddition {
    typealias ErrType = CustomError2
    case error3 = "Error 3 summary"
    case error4 = "Error 4 summary"
}

struct CustomError2: Err {
    typealias AdditionType = [String]?
    var summary: String!
    var explain: String?
    var file: String!
    var line: Int!
    var mark: Int?

    var a1: String!
    var a2: String!

    mutating func initAddtions(_ data: [String]?) {
        if let d = data {
            self.a1 = d[0]
            self.a2 = d[1]
        } else {
            self.a1 = "Unset a1"
            self.a2 = "Unset a2"
        }
    }
}

typealias B = ErrorTypes2