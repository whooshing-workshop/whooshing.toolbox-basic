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

    static let explain2 = "test explain 2"
    static let mark2 = Int.random(in: 100..<200)
    static let datas2 = (0..<2).map { _ in Int.random(in: 100...300) }
    static let err2 = A.error1

    static let subErr = A.error2.d([1, 2], #file, #line)

    let err2 = Self.err2.d(Self.explain2, Self.mark2, adds: Self.datas2, (#file, #line))

    @Test("测试 ErrListWithOptionAddition 扩展的参数传递") func testErrListWithOptionAddition() {
        let error = Self.err.d(Self.explain, Self.mark, adds: Self.datas, (#file, #line))
        #expect(error.summary == B.error3.rawValue)
        #expect(error.explain == Self.explain)
        #expect(error.mark == Self.mark)
        #expect(error.a1 == Self.datas[0])
        #expect(error.a2 == Self.datas[1])
        #expect(error.file == #file)
        #expect(error.line == 25)
    }

    @Test("测试 ErrListWithIndeedAddition 扩展的参数传递") func testErrListWithIndeedAddition() {
        #expect(err2.summary == A.error1.rawValue)
        #expect(err2.explain == Self.explain2)
        #expect(err2.mark == Self.mark2)
        #expect(err2.a1 == Self.datas2[0])
        #expect(err2.a2 == Self.datas2[1])
        #expect(err2.file == #file)
        #expect(err2.line == 22)
    }

    let explains = [0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0]
    let marks = [0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1]
    let datass = [0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1]
    let subErrs = [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1]
    let lineStart = 72

    @Test("测试所有方法的参数传递", arguments: [
        0: Self.err.d(#file, #line),
        1: Self.err.d(Self.explain, #file, #line),
        2: Self.err.d(Self.explain, (#file, #line)),
        3: Self.err.d(Self.mark, #file, #line),
        4: Self.err.d(Self.mark, adds: Self.datas, #file, #line),
        5: Self.err.d(Self.explain, Self.mark, adds: Self.datas, (#file, #line)),
        6: Self.err.d(Self.explain, Self.mark, (#file, #line)),
        7: Self.err.d(adds: Self.datas ,#file, #line),
        8: Self.err.d(Self.mark, adds: Self.datas, #file, #line),
        
        9: Self.err.d(Self.subErr, #file, #line),
        10: Self.err.d(Self.explain, Self.subErr, #file, #line),
        11: Self.err.d(Self.explain, Self.subErr, (#file, #line)),
        12: Self.err.d(Self.mark, Self.subErr, #file, #line),
        13: Self.err.d(Self.mark, Self.subErr, adds: Self.datas, #file, #line),
        14: Self.err.d(Self.explain, Self.mark, Self.subErr, adds: Self.datas, (#file, #line)),
        15: Self.err.d(Self.explain, Self.mark, Self.subErr, (#file, #line)),
        16: Self.err.d(Self.subErr, adds: Self.datas ,#file, #line),
        17: Self.err.d(Self.mark, Self.subErr, adds: Self.datas, #file, #line),
    ])
    func testFuncs(i: Int, e: CustomError2) {
        #expect(explains[i] == 0 ? e.explain == nil : e.explain == Self.explain)
        #expect(marks[i] == 0 ? e.mark == nil : e.mark == Self.mark)
        #expect(datass[i] == 0 ? e.a1 == "Unset a1" : e.a1 == Self.datas[0])
        #expect(datass[i] == 0 ? e.a2 == "Unset a2" : e.a2 == Self.datas[1])
        #expect(subErrs[i] == 0 ? e.subError == nil : e.subError as? A.ErrType == Self.subErr)
        #expect(e.file == #file)
        #expect(e.line == lineStart)
    }

    @Test("测试 Err.subErr() 函数") func testSubError() async throws {
        #expect(Self.err.d(#file, #line).subErr(Self.subErr).subError as? A.ErrType == Self.subErr)
    }

    @Test("测试 Guard 以及 == 函数") func testGuardFunction() {
        do {
            let _ = try Guard(
                { throw A.error1.d("hello", 1005, [1, 2, 3], #file, #line) }, 
                throw: B.error3.d(3008, #file, #line)
            )
            #expect(Bool(false))
        } catch let err as B.ErrType {
            #expect(err.summary == B.error3.rawValue)
            #expect(err.mark == 3008)
            #expect(err.subError as! A.ErrType != A.error1.d(1005, adds: [1, 2, 3], #file, #line))
            #expect(err.subError as! A.ErrType == A.error1.d(1005, adds: [1, 2, 3], #file, 89))
            #expect((err.subError as! A.ErrType).isSameType(of: A.error1.d("hello", 5000 as Int, [0, 0], "Test", 89)))
        } catch {
            #expect(Bool(false))
        }
    }
}

// MARK: - 类型定义

enum ErrorTypes1: String, ErrListWithIndeedAddition {
    typealias ErrType = CustomError1
    var domain: String { "错误测试1" }
    case error1 = "Error 1 summary"
    case error2 = "Error 2 summary"
}

struct CustomError1: Err {
    typealias AdditionType = [Int]
    var domain: String!
    var summary: String!
    var explain: String?
    var file: String!
    var line: Int!
    var mark: Int?
    var subError: Error?

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
    var domain: String { "错误测试2" }
    case error3 = "Error 3 summary"
    case error4 = "Error 4 summary"
}

struct CustomError2: Err {
    typealias AdditionType = [String]?
    var domain: String!
    var summary: String!
    var explain: String?
    var file: String!
    var line: Int!
    var mark: Int?
    var subError: Error?

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