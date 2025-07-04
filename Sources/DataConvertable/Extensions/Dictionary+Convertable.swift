import Foundation
import ErrorHandle

@frozen
public enum DictionaryEncodeErrcase: String, ErrList {
    case keyFailed = "字典 Key 编码失败"
    case valueFailed = "字典 Value 编码失败"
}

@frozen
public enum DictionaryDecodeErrcase: String, ErrList {
    case keyFailed = "字典 Key 解码失败"
    case valueFailed = "字典 Value 解码失败"
}

extension Dictionary: EncodingSafeDataConvertable where Key: EncodingSafeDataConvertable, Value: EncodingSafeDataConvertable {
    @inlinable
    public static func new(data: Data) -> Self {
        try! newDictionary(data: data).get()
    }
}

extension Dictionary: DecodingSafeDataConvertable where Key: DecodingSafeDataConvertable, Value: DecodingSafeDataConvertable {
    @inlinable
    public var data: Data {
        try! getData(from: self).get()
    }
}

extension Dictionary: EncodingThrowableDataConvertable where Key: EncodingThrowableDataConvertable, Value: EncodingThrowableDataConvertable {
    @inlinable
    public static func make(data: Data) -> Res<Self, DictionaryEncodeErrcase> {
        newDictionary(data: data)
    }
}

extension Dictionary: DecodingThrowableDataConvertable where Key: DecodingThrowableDataConvertable, Value: DecodingThrowableDataConvertable {
    @inlinable
    public var dataRes: Res<Data, DictionaryDecodeErrcase> {
        getData(from: self)
    }
}

@inlinable
func newDictionary<K, V>(data: Data) -> Res<[K: V], DictionaryEncodeErrcase> where K: EncodingThrowableDataConvertable, V: EncodingThrowableDataConvertable {
    let lsize = MemoryLayout.size(ofValue: Int.self)
    var curLength = 0
    var res: [K: V] = [:]
    while (curLength < data.count) {
        let kLength = Int.new(data: data.subdata(in: curLength..<(curLength + lsize))); curLength += lsize
        let vLength = Int.new(data: data.subdata(in: curLength..<(curLength + lsize))); curLength += lsize
        let k: K
        do {
            k = try K.make(data: data.subdata(in: curLength..<(curLength + kLength))).get()
        } catch {
            return .failure(.keyFailed, subErr: error)
        }
        curLength += kLength
        
        let v: V
        do {
            v = try V.make(data: data.subdata(in: curLength..<(curLength + vLength))).get()
        } catch {
            return .failure(.valueFailed, subErr: error)
        }
        
        curLength += vLength
        res[k] = v
    }
    return .success(res)
}

@inlinable
func getData<K, V>(from dictionary: [K: V]) -> Res<Data, DictionaryDecodeErrcase> where K: DecodingThrowableDataConvertable, V: DecodingThrowableDataConvertable {
    var res = Data()
    for (key, value) in dictionary {
        let kData: Data
        do {
            kData = try key.dataRes.get()
        } catch {
            return .failure(.keyFailed, subErr: error)
        }
        
        let vData: Data
        do {
            vData = try value.dataRes.get()
        } catch {
            return .failure(.valueFailed, subErr: error)
        }
        res += kData.count.data + vData.count.data + kData + vData
    }
    return .success(res)
}
