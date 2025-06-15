import Testing
@testable import NIOAdvanced
import Foundation
import ErrorHandle
import NIOPosix
import NIOCore

@Suite("NIOAdvanced-测试")
struct NIOAdvancedTests {
    
    let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount).next()
    
    enum Error1: String, Error, ErrList {
        case exampleError11
        case exampleError12
    }
    
    enum Error2: String, Error, ErrList {
        case exampleError21
        case exampleError22
    }
    
    let string1 = "Testing String 1"
    let string2 = "Testing String 2"
    let string3 = "Testing String 3"
    
    let int1 = 100
    let int2 = 101
    let int3 = 102
    
    @Test("一般用法测试")
    func normalTest() async throws {
        let result = self.eventLoop.makeSucceededResult(string1, throws: Error1.self)
        
        result.flatMapThrowing { value in
            #expect(value == string1)
            return value
        }.flatMap { value in
            self.eventLoop.makeSucceededResult(string2)
        }.flatMapThrowing { value in
            #expect(value == string2)
            return value
        }.map { value in
            string3
        }.whenComplete { result in
            switch result {
            case .success(let value): #expect(value == string3)
            case .failure(_): fatalError()
            }
        }
    }
    
    @Test("进阶测试")
    func errorCastTest() async throws {
        let result = self.eventLoop.makeSucceededResult(string1, throws: Error1.self)
        
        let r = result.flatMap { value in
            self.eventLoop.makeFailedResult(.exampleError11)
        }.flatMapErrorThrowing { error in
            #expect(error == .exampleError11)
            return string2
        }.flatMapError { value in
            self.eventLoop.makeFailedResult(Error2.exampleError21)
        }.flatMapErrorThrowing { error in
            #expect(error == .exampleError21)
            return string2
        }.flatMap { _ in
            self.eventLoop.makeSucceededResult(int1)
        }.map { value in
            #expect(value == int1)
            return value
        }.flatCast { value in
            self.eventLoop.makeSucceededResult(string3, throws: Error1.self)
        }
            
        r.flatMapThrowing { value in
            #expect(value == string3)
            return value
        }.flatMap { value -> EventLoopResult<Never, Error1> in
            self.eventLoop.makeFailedResult(.exampleError12)
        }.whenComplete { result in
            switch result {
            case .success: fatalError()
            case .failure(let error): #expect(error == .exampleError12)
            }
        }
    }
    
    @Test("进阶错误解包测试-1")
    func advancedErrorCastTest1() async throws {
        varyResult { () throws(Error2) in
            throw .exampleError21
        } _: { value in
            self.eventLoop.makeSucceededResult(string2, throws: Error2.self)
        }.whenComplete { res in
            switch res {
            case .success(_): fatalError()
            case .failure(let error):
                #expect(error.error == .exampleError11)
                #expect(error.subError as? Error2 == .exampleError21)
            }
        }
    }
    
    @Test("进阶错误解包测试-2")
    func advancedErrorCastTest2() async throws {
        varyResult { () throws(Error2) in
            int3
        } _: { value in
            self.eventLoop.makeSucceededResult(string2, throws: Error2.self)
        }.whenComplete { res in
            switch res {
            case .success(let value): #expect(value == string2)
            case .failure(_): fatalError()
            }
        }
    }
    
    @Test("进阶错误解包测试-3")
    func advancedErrorCastTest3() async throws {
        varyResult { () throws(Error2) in
            int3
        } _: { value in
            self.eventLoop.makeFailedResult(Error2.exampleError22)
        }.whenComplete { res in
            switch res {
            case .success(_): fatalError()
            case .failure(let error):
                #expect(error.error == .exampleError12)
                #expect(error.subError as? Error2 == .exampleError22)
            }
        }
    }
    
    @Test("进阶错误解包测试-4")
    func advancedErrorCastTest4() async throws {
        varyResult { () throws(Error2) in
            throw .exampleError21
        } _: { value in
            self.eventLoop.makeFailedResult(Error2.exampleError22)
        }.whenComplete { res in
            switch res {
            case .success(_): fatalError()
            case .failure(let error):
                #expect(error.error == .exampleError11)
                #expect(error.subError as? Error2 == .exampleError21)
            }
        }
    }
    
    func varyResult<NewError>(
        _ callback1: @escaping @Sendable () throws(Error2) -> Int,
        _ callback2: @escaping @Sendable (String) -> EventLoopResult<String, NewError>
    ) -> EventLoopResult<String, BscError<Error1>> {
        subAction(callback1)
            .errCast(Error1.exampleError11)
            .flatCast { _ in callback2(string2).errCast(Error1.exampleError12) }
    }
    
    func subAction(
        _ callback: @escaping @Sendable () throws(Error2) -> Int
    ) -> EventLoopResult<Int, Error2> {
        self.eventLoop.submitResult(callback)
    }
}
