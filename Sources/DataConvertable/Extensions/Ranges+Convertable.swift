import Foundation
import ErrorHandle

extension Range: SafeDataConvertable where Bound: SafeDataConvertable {
    @inlinable
    public static func new(data: Data) -> Self {
        try! newRange(from: data).get()
    }
    
    @inlinable
    public var data: Data {
        try! getData(from: self).get()
    }
}

extension Range: ThrowableDataConvertable where Bound: ThrowableDataConvertable {
    @inlinable
    public static func make(data: Data) -> Res<Self, RangeEncodeErrcase> {
        newRange(from: data)
    }
    
    @inlinable
    public var dataRes: Res<Data, RangeDecodeErrcase> {
        getData(from: self)
    }
}

extension ClosedRange: SafeDataConvertable where Bound: SafeDataConvertable {
    @inlinable
    public static func new(data: Data) -> Self {
        try! newClosedRange(from: data).get()
    }
    
    @inlinable
    public var data: Data {
        try! getData(from: self).get()
    }
}

extension ClosedRange: ThrowableDataConvertable where Bound: ThrowableDataConvertable {
    @inlinable
    public static func make(data: Data) -> Res<Self, ClosedRangeEncodeErrcase> {
        newClosedRange(from: data)
    }
    
    @inlinable
    public var dataRes: Res<Data, ClosedRangeDecodeErrcase> {
        getData(from: self)
    }
}

@frozen
public enum RangeEncodeErrcase: String, ErrList {
    case lowerBoundFailed = "Range 低边界编码失败"
    case upperBoundFailed = "Range 高边界编码失败"
}

@frozen
public enum RangeDecodeErrcase: String, ErrList {
    case lowerBoundFailed = "Range 低边界解码失败"
    case upperBoundFailed = "Range 高边界解码失败"
}

@inlinable
func newRange<T>(from data: Data) -> Res<Range<T>, RangeEncodeErrcase> where T: ThrowableDataConvertable {
    let size = MemoryLayout.size(ofValue: Int.self)
    let lowerBoundSize = Int.new(data: data.prefix(size))
    let upperBoundSize = Int.new(data: data.subdata(in: size..<(size + size)))
    
    let lowerBound: T
    do {
        lowerBound = try T.make(data: data.subdata(in: (size * 2)..<(size * 2 + lowerBoundSize))).get()
    } catch {
        return .failure(.lowerBoundFailed)
    }
    
    let upperBound: T
    do {
        upperBound = try T.make(data: data.suffix(upperBoundSize)).get()
    } catch {
        return .failure(.upperBoundFailed)
    }
    
    return .success(Range<T>(uncheckedBounds: (lower: lowerBound, upper: upperBound)))
}

@inlinable
func getData<T>(from range: Range<T>) -> Res<Data, RangeDecodeErrcase> where T: ThrowableDataConvertable {
    let lowerData: Data
    do {
        lowerData = try range.lowerBound.dataRes.get()
    } catch {
        return .failure(.lowerBoundFailed)
    }
    
    let upperData: Data
    do {
        upperData = try range.upperBound.dataRes.get()
    } catch {
        return .failure(.upperBoundFailed)
    }

    return .success(lowerData.count.data + upperData.count.data + lowerData + upperData)
}

@frozen
public enum ClosedRangeEncodeErrcase: String, ErrList {
    case lowerBoundFailed = "ClosedRange 低边界编码失败"
    case upperBoundFailed = "ClosedRange 高边界编码失败"
}

@frozen
public enum ClosedRangeDecodeErrcase: String, ErrList {
    case lowerBoundFailed = "ClosedRange 低边界解码失败"
    case upperBoundFailed = "ClosedRange 高边界解码失败"
}

@inlinable
func newClosedRange<T>(from data: Data) -> Res<ClosedRange<T>, ClosedRangeEncodeErrcase> where T: ThrowableDataConvertable {
    let size = MemoryLayout.size(ofValue: Int.self)
    let lowerBoundSize = Int.new(data: data.prefix(size))
    let upperBoundSize = Int.new(data: data.subdata(in: size..<(size + size)))
    
    let lowerBound: T
    do {
        lowerBound = try T.make(data: data.subdata(in: (size * 2)..<(size * 2 + lowerBoundSize))).get()
    } catch {
        return .failure(.lowerBoundFailed)
    }
    
    let upperBound: T
    do {
        upperBound = try T.make(data: data.suffix(upperBoundSize)).get()
    } catch {
        return .failure(.upperBoundFailed)
    }
    
    return .success(ClosedRange<T>(uncheckedBounds: (lower: lowerBound, upper: upperBound)))
}

@inlinable
func getData<T>(from closedRange: ClosedRange<T>) -> Res<Data, ClosedRangeDecodeErrcase> where T: ThrowableDataConvertable {
    let lowerData: Data
    do {
        lowerData = try closedRange.lowerBound.dataRes.get()
    } catch {
        return .failure(.lowerBoundFailed)
    }
    
    let upperData: Data
    do {
        upperData = try closedRange.upperBound.dataRes.get()
    } catch {
        return .failure(.upperBoundFailed)
    }

    return .success(lowerData.count.data + upperData.count.data + lowerData + upperData)
}
