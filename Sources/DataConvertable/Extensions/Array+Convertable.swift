import Foundation
import ErrorHandle

extension Array: EncodingSafeDataConvertable where Element: EncodingSafeDataConvertable {
    public static func new(data: Data) -> [Element] {
        try! newArray(data: data).get()
    }
}

extension Array: DecodingSafeDataConvertable where Element: DecodingSafeDataConvertable {
    public var data: Data {
        try! getData(from: self).get()
    }
}

extension Array: EncodingThrowableDataConvertable where Element: EncodingThrowableDataConvertable {
    public static func make(data: Data) -> Result<Self, Element.EncodeErrType> {
        newArray(data: data)
    }
}

extension Array: DecodingThrowableDataConvertable where Element: DecodingThrowableDataConvertable {
    public var dataRes: Result<Data, Element.DecodeErrType> {
        getData(from: self)
    }
}

func newArray<T>(data: Data) -> Result<[T], T.EncodeErrType> where T: EncodingThrowableDataConvertable {
    let lsize = MemoryLayout.size(ofValue: Int.self)
    var curLength = 0
    var res: [T] = []
    while (curLength < data.count) {
        let kLength = Int.new(data: data.subdata(in: curLength..<(curLength + lsize)))
        curLength += lsize
        let r = T.make(data: data.subdata(in: curLength..<(curLength + kLength))).map { value in
            curLength += kLength
            res.append(value)
        }
        if case let .failure(err) = r {
            return .failure(err)
        }
    }
    return .success(res)
}

func getData<T>(from array: [T]) -> Result<Data, T.DecodeErrType> where T: DecodingThrowableDataConvertable {
    var res = Data()
    for element in array {
        let r = element.dataRes.map { data in
            res += data.count.data + data
        }
        if case let .failure(err) = r {
            return .failure(err)
        }
    }
    return .success(res)
}




//import Foundation
//import ErrorHandle
//
//public enum ArrayErrcase: String, ErrList {
//    case encodeFailed = "字典从 Data 编码失败"
//    case decodeFailed = "数组解码为 Data 失败"
//}
//
//extension Array: EncodingSafeDataConvertable where Element == any EncodingSafeDataConvertable {
//    public static func new(data: Data) -> [Element] {
//        try! newArray(data: data).get()
//    }
//}
//
//extension Array: DecodingSafeDataConvertable where Element == any DecodingSafeDataConvertable {
//    public var data: Data {
//        try! getData(from: self).get()
//    }
//}
//
//extension Array: EncodingThrowableDataConvertable where Element == any EncodingThrowableDataConvertable {
//    public static func new(data: Data) -> Res<Self, ArrayErrcase> {
//        newArray(data: data)
//    }
//}
//
//extension Array: DecodingThrowableDataConvertable where Element == any DecodingThrowableDataConvertable {
//    public var data: Res<Data, ArrayErrcase> {
//        getData(from: self)
//    }
//}
//
//func newArray<T>(data: Data) -> Res<[T], ArrayErrcase> where T: EncodingThrowableDataConvertable {
//    let lsize = MemoryLayout.size(ofValue: Int.self)
//    var curLength = 0
//    var res: [T] = []
//    while (curLength < data.count) {
//        let kLength = Int.new(data: data.subdata(in: curLength..<(curLength + lsize)))
//        curLength += lsize
//        let r = T.new(data: data.subdata(in: curLength..<(curLength + kLength))).map { value in
//            curLength += kLength
//            res.append(value)
//        }
//        if case let .failure(err) = r {
//            return .failure(.encodeFailed, subErr: err)
//        }
//    }
//    return .success(res)
//}
//
//func getData(from array: [any DecodingThrowableDataConvertable]) -> Res<Data, ArrayErrcase> {
//    var res = Data()
//    for element in array {
//        let r = element.data.map { data in
//            res += data.count.data + data
//        }
//        if case let .failure(err) = r {
//            return .failure(.decodeFailed, subErr: err)
//        }
//    }
//    return .success(res)
//}
