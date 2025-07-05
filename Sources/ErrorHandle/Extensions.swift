/**
    #### 错误转换函数
    
    当某个 api 的 throw 抛出的错误，并非你所希望的错误类型，你可以转换其抛出的错误。例如：

    -----
    ### 转换抛出错误

    以下模拟了一个函数，并且抛出了一个错误。但是有时，你可能并不希望该函数抛出这样的错误。且该函数由于某些原因你无法修改(例如，该函数来自其他第三方库)
    ``` swift
    func throwError() throws {
        ... do something ...
        // 抛出 SomeError.err
        throw SomeError.err
    }

    enum WanttedErrorTypes: String, ErrList {
        case error1 = "错误 1"
        case error2 = "错误 2"
        case error3 = "错误 3"
        ...
    }

    typealias A = WanttedErrorTypes

    try throwError() // 抛出错误为 SomeError.err，并不是我想要的，而我希望它若发生错误便抛出 A.error1.d("错误的解释...", 3) 以适应 Whooshing 的错误处理系统。
    ```
    你可以使用传统的 `do - catch` 结构来完成，像下面这样：

    ``` swift
    do {
        try throwError()
    } catch {   // 当 throwError() 方法发生错误并抛出错误后，捕获该错误，并改为 throw 另一个，并将 error 作为 subError 传递。
        throw A.error1.d("错误的解释...", 3).subErr(error)
    }
    ```

    也可以使用所提供的 required(_, _) 方法：

    ``` swift
    // 当 throwError() 发生错误时，会抛出所期望的错误。
    try required(throw: A.error1.d("错误的解释...", 3)) {
        try throwError()
    }
    ```

    事实上这两种方式的实现方法是一致的，但后者更简洁。
*/
@inlinable
public func required<T, G>(throws to: G, _ performing: () throws -> T) throws(G) -> T where G: Err {
    do {
        let res = try performing()
        return res
    } catch let err {
        throw to.subErr(err)
    }
}

@inlinable
public func required<G, T>(
    throws to: G,
    _ explain: String? = nil,
    file: String = #file,
    line: Int = #line,
    function: String = #function,
    _ performing: () throws -> T
) throws(G.ErrType) -> T where G: ErrList {
    do {
        let res = try performing()
        return res
    } catch let err {
        throw .init(to, explain, file: file, line: line, function: function).subErr(err)
    }
}

@inlinable
public func flatError<T, G>(as errorType: T.Type = T.self, _ callback: () throws -> G) throws(T) -> G {
    do {
        return try callback()
    } catch {
        throw error as! T
    }
}

@inlinable
public func flatError<T, G>(as errorType: T.Type = T.self, _ callback: () async throws -> G) async throws(T) -> G {
    do {
        return try await callback()
    } catch {
        throw error as! T
    }
}
 
@inlinable
public func required<T, G>(throws to: G, _ performing: () async throws -> T) async throws(G) -> T where G: Err {
    do {
        let res = try await performing()
        return res
    } catch let err {
        throw to.subErr(err)
    }
}

@inlinable
public func required<G, T>(
    throws to: G,
    _ explain: String? = nil,
    file: String = #file,
    line: Int = #line,
    function: String = #function,
    _ performing: () async throws -> T
) async throws(G.ErrType) -> T where G: ErrList {
    do {
        let res = try await performing()
        return res
    } catch let err {
        throw .init(to, explain, file: file, line: line, function: function).subErr(err)
    }
}

public typealias Res<G, T> = Result<G, T.ErrType> where T: ErrList

public extension Result where Failure: Err {
    @inlinable
    init(
        throws error: Failure.ErrorList,
        _ explain: String? = nil,
        file: String = #file,
        line: Int = #line,
        function: String = #function,
        catching body: () throws -> Success
    ) {
        self.init { () throws(Failure) in
            do {
                return try body()
            } catch let err {
                throw Failure.init(error, explain, file: file, line: line, function: function).subErr(err)
            }
        }
    }
    
    @inlinable
    static func async(
        throws error: Failure.ErrorList,
        _ explain: String? = nil,
        file: String = #file,
        line: Int = #line,
        function: String = #function,
        catching body: () async throws -> Success
    ) async -> Self {
        do {
            return .success(try await body())
        } catch let err {
            return .failure(Failure.init(error, explain, file: file, line: line, function: function).subErr(err))
        }
    }
    
    @inlinable
    static func failure(
        _ error: Failure.ErrorList,
        _ explain: String? = nil,
        subErr: Error? = nil,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) -> Self {
        .failure(Failure.init(error, explain, file: file, line: line, function: function).subErr(subErr))
    }
}

public extension Result {
    @inlinable
    consuming func mapError<T>(
        as error: T,
        _ explain: String? = nil,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) -> Result<Success, T.ErrType> where T : ErrList {
        self.mapError { err in
            .init(error, explain, file: file, line: line, function: function).subErr(err)
        }
    }
    
    @inlinable
    static func async(catching body: () async throws(Failure) -> Success) async -> Self {
        do {
            return .success(try await body())
        } catch let err {
            return .failure(err as! Failure)
        }
    }
}
