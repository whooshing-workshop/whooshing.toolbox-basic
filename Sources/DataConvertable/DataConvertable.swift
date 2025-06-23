import Foundation
import ErrorHandle

/**
    #### 实现该协议的类型，即表示其转换可能失败，引发 throw

    例如 `String` 类型默认实现了该协议，因此它可以：
    ``` swift
    do {
        // 声明一个字符串
        let string = "Hello World!"
        // 将字符串转为 Data
        let data = try string.data()
        // 重新将 Data 转为字符串
        let newString = try String(data: data)

        print(string == newString)      // true
    } catch let err {
        // 数据转换时出现了错误，需要处理错误
        print(err)
    }
    ```

    无论是转为 Data 或是从 Data 转回，都需要使用 try 修饰，以处理其错误，当然若你十分确定不会出错，可以强制执行：
    ``` swift
    // 声明一个字符串
    let string = "Hello World!"
    // 将字符串转为 Data
    let data = try! string.data()
    // 重新将 Data 转为字符串
    let newString = try! String(data: data)

    print(string == newString)      // true
    ```

    另外一个协议 `SafeDataConvertable`，表示该类型执行转换时是安全的，不会抛出错误
    
    -----
    ### 数组 与 Data 互转

    数组是否为 Safe 的转换类型，取决于其中的类型，若其中的类型是 Throwable 的，那么该 Array 便为 Throwable；
    若其中类型为 Safe，则该 Array 为 Safe：

    ``` swift
    // Int 类型是 Safe 的
    let arr = [1, 2, 3]
    let arrData = arr.data()
    let newArr = [Int](data: arrData)

    print(arr == newArr)        // true
    ```

    而若使用 ```[String]``` 类型，则 Array 变为 Throwable：

    ``` swift
    do {
        let arr = ["1", "2", "3"]
        let arrData = try arr.data()
        let newArr = try [String](data: arrData)
        print(arr == newArr)            // true
    } catch let err {
        print(err)
    }
    ```
    -----
    ### 字典类型与 Data 互转

    字典是 Throwable 的转换类型，无论 Key 和 Value 如何

    ``` swift
    do {
        let dic = [1: "One", 2: "Two", 3: "Three"]
        let data = try dic.data()
        let newDic = try [Int: String](data: data)

        print(dic == newDic)        // true
    } catch let err {
        print(err)
    }
    ```
    -----
    ### 目前所有实现该协议的类型：

    - `SafeDataConvertable`
        - `Data`
        - `Int`
        - `Int8`
        - `Int16`
        - `Int32`
        - `Int64`
        - `UInt`
        - `UInt8`
        - `UInt16`
        - `UInt32`
        - `UInt64`
        - `Float`
        - `Double`
        - `Decimal`
        - `Date`
        - `Dictionary<SafeDataConvertable: SafeDataConvertable>`
        - `Range<SafeDataConvertable>`
        - `ClosedRange<SafeDataConvertable>`
        - `Array<SafeDataConvertable>`

    - `ThrowableDataConvertable`
        - `String`
        - `Base64String`
        - `UUID`
        - `Dictionary<key == ThrowableDataConvertable or value == ThrowableDataConvertable>`
        - `Range<ThrowableDataConvertable>`
        - `ClosedRange<ThrowableDataConvertable>`
        - `Array<ThrowableDataConvertable>`

    你也可以自己实现该协议，以创建转换类型
*/
public typealias ThrowableDataConvertable = EncodingThrowableDataConvertable & DecodingThrowableDataConvertable

public protocol EncodingThrowableDataConvertable {
    associatedtype EncodeErrType: Error
    static func make(data: Data) -> Result<Self, EncodeErrType>
}

public protocol DecodingThrowableDataConvertable {
    associatedtype DecodeErrType: Error
    var dataRes: Result<Data, DecodeErrType> { get }
}

/**
    #### 实现该协议的类型，即表示其进行类型转换一定成功

    例如，```Int``` 类型(包括所有数字类型)，默认实现了该协议，因此它可以：
    ``` swift
    let int = 100
    let data = int.data()
    let newInt = Int(data: data)
    ```
    另见协议 `ThrowableDataConvertable`
*/
public typealias SafeDataConvertable = EncodingSafeDataConvertable & DecodingSafeDataConvertable

public protocol EncodingSafeDataConvertable: EncodingThrowableDataConvertable {
    associatedtype EncodeErrType = Never
    /// 从 Data 初始化该类型，无错误抛出
    static func new(data: Data) -> Self
}

public protocol DecodingSafeDataConvertable: DecodingThrowableDataConvertable {
    associatedtype DecodeErrType = Never
    /// 转换为 Data，无错误抛出
    var data: Data { get }
}

public extension EncodingSafeDataConvertable {
    static func make(data: Data) -> Result<Self, EncodeErrType> {
        .success(new(data: data))
    }
}

public extension DecodingSafeDataConvertable {
    var dataRes: Result<Data, DecodeErrType> {
        .success(data)
    }
}
