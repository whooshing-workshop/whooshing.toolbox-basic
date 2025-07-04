import Foundation
import ErrorHandle

extension Array: EncodingSafeDataConvertable where Element: EncodingSafeDataConvertable {
    @inlinable
    public static func new(data: Data) -> [Element] {
        try! newArray(data: data).get()
    }
}

extension Array: DecodingSafeDataConvertable where Element: DecodingSafeDataConvertable {
    @inlinable
    public var data: Data {
        try! getData(from: self).get()
    }
}

extension Array: EncodingThrowableDataConvertable where Element: EncodingThrowableDataConvertable {
    @inlinable
    public static func make(data: Data) -> Result<Self, Element.EncodeErrType> {
        newArray(data: data)
    }
}

extension Array: DecodingThrowableDataConvertable where Element: DecodingThrowableDataConvertable {
    @inlinable
    public var dataRes: Result<Data, Element.DecodeErrType> {
        getData(from: self)
    }
}

@inlinable
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

@inlinable
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
