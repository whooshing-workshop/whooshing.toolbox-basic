import Testing
@testable import DataConvertable
import Foundation

@Suite("数据转换模块-测试")
struct DataConvertableTest {
    
    @Test("字符串转换测试")
    func testStringConversion() {
        let originalString = "Hello, World!"
        do {
            let data = try originalString.data()
            let convertedString = try String(data: data)
            #expect(convertedString == originalString)
        } catch {
            #expect(Bool(false), "字符串转换抛出错误: \(error)")
        }
    }
    
    @Test("Base64 字符串转换测试")
    func testBase64StringConversion() {
        let originalString = Base64String(Data((0..<16).map { _ in UInt8.random(in: 0...255) }).base64EncodedString())
        do {
            let data = try originalString.data()
            let convertedString = Base64String(data: data)
            #expect(convertedString == originalString)
        } catch {
            #expect(Bool(false), "Base64 字符串转换抛出错误: \(error)")
        }
    }
    
    @Test("整数转换测试")
    func testIntConversion() {
        let originalInt: Int = 42
        let data = originalInt.data()
        let convertedInt = Int(data: data)
        #expect(convertedInt == originalInt, "整数转换失败")
    }
    
    @Test("整数类型擦除转换测试")
    func testIntTypeEraseConversion() {
        let originalInt: Int = 42
        let data = originalInt.data()
        let convertedInt = AnySafeDataConvertable(data: data)
        #expect(convertedInt.cast(to: Int.self) == originalInt, "整数类型擦除转换失败")
    }
    
    @Test("数组转换测试")
    func testArrayConversion() {
        let originalArray: [Int] = [1, 2, 3, 4, 5]
        let data = originalArray.data()
        let convertedArray = [Int](data: data)
        #expect(convertedArray == originalArray, "数组转换失败")
    }
    
    @Test("浮点数转换测试")
    func testFloatConversion() {
        let originalFloat: Float = 3.14
        let data = originalFloat.data()
        let convertedFloat = Float(data: data)
        #expect(convertedFloat == originalFloat, "浮点数转换失败")
    }
    
    @Test("双精度浮点数转换测试")
    func testDoubleConversion() {
        let originalDouble: Double = 3.14159265359
        let data = originalDouble.data()
        let convertedDouble = Double(data: data)
        #expect(convertedDouble == originalDouble, "双精度浮点数转换失败")
    }
    
    @Test("字典转换测试")
    func testDictionaryConversion() {
        let originalDictionary: [String: Int] = ["one": 1, "two": 2, "three": 3]
        do {
            let data = try originalDictionary.data()
            let convertedDictionary = try [String: Int](data: data)
            #expect(convertedDictionary == originalDictionary, "字典转换失败")
        } catch {
            #expect(Bool(false), "字典转换抛出错误: \(error)")
        }
    }
    
    @Test("Safe 字典转换测试")
    func testSafeDictionaryConversion() {
        let originalDictionary: [Int: Int] = [1: 1, 2: 2, 3: 3]
        let data = originalDictionary.data()
        let convertedDictionary = [Int: Int](data: data)
        #expect(convertedDictionary == originalDictionary, "字典转换失败")
    }
    
    @Test("字典类型擦除测试")
    func testTypeEraseConversion() {
        let originalDictionary: [String: Int] = ["one": 1, "two": 2, "three": 3]
        do {
            let data = try originalDictionary.data()
            let convertedDictionary = try [String: AnySafeDataConvertable](data: data)
            let res = convertedDictionary.reduce(into: [String: Int]()) { $0[$1.key] = $1.value.cast(to: Int.self) }
            #expect(res == originalDictionary, "字典类型擦除失败")
        } catch {
            #expect(Bool(false), "字典类型擦除抛出错误: \(error)")
        }
    }
    
    @Test("字典类型擦除测试 2")
    func testTypeEraseConversion_2() {
        let o: [Int: Int] = [1: 1, 2: 2, 3: 3]
        let originalDictionary: [AnySafeDataConvertable: AnySafeDataConvertable] = o.any
        let data = originalDictionary.data()
        let convertedDictionary = [Int: Int](data: data)
        #expect(convertedDictionary == o, "字典类型擦除测试 2 失败")
    }
    
    @Test("字典类型擦除测试 3")
    func testTypeEraseConversion_3() {
        let o: [String: (any ThrowableDataConvertable)?] = ["one": 1, "two": 2, "three": 3, "four": nil]
        let originalDictionary: [AnyThrowableDataConvertable: AnyThrowableDataConvertable] = o.filtered.any
        do {
            let data = try originalDictionary.data()
            let convertedDictionary = try [String: Int](data: data)
            #expect(convertedDictionary == o.filtered.reduce(into: [String: Int]()) { $0[$1.key] = ($1.value as! Int) }, "字典类型擦除测试 3 失败")
        } catch {
            #expect(Bool(false), "字典类型擦除 3 抛出错误: \(error)")
        }
    }
    
    @Test("空字典转换测试")
    func testEmptyDictionaryConversion() {
        let originalDictionary: [String: Int] = [:]
        do {
            let data = try originalDictionary.data()
            let convertedDictionary = try [String: AnySafeDataConvertable](data: data)
            let res = convertedDictionary.reduce(into: [String: Int]()) { $0[$1.key] = $1.value.cast(to: Int.self) }
            #expect(res == originalDictionary, "字典转换失败")
        } catch {
            #expect(Bool(false), "字典转换抛出错误: \(error)")
        }
    }
    
    @Test("UUID 转换测试")
    func testUUIDConversion() {
        let original = UUID()
        do {
            let data = original.data()
            let converted = try UUID(data: data)
            #expect(converted == original, "UUID 转换失败")
        } catch {
            #expect(Bool(false), "UUID 转换抛出错误: \(error)")
        }
    }
    
    @Test("Range 转换测试")
    func rangeConversion() {
        let original = 0..<100
        let data = original.data()
        let converted = Range<Int>(data: data)
        #expect(converted == original, "ClosedRange 转换失败")
    }
    
    @Test("Range Throwable 转换测试")
    func rangeThrowableConversion() {
        let original = "a"..<"z"
        do {
            let data = try original.data()
            let converted = try Range<String>(data: data)
            #expect(converted == original, "ClosedRange 转换失败")
        } catch {
            #expect(Bool(false), "UUID 转换抛出错误: \(error)")
        }
    }
    
    @Test("ClosedRange 转换测试")
    func testRangeConversion() {
        let original = 0...100
        let data = original.data()
        let converted = ClosedRange<Int>(data: data)
        #expect(converted == original, "ClosedRange 转换失败")
    }
    
    @Test("ClosedRange Throwable 转换测试")
    func testRangeThrowableConversion() {
        let original = "a"..."z"
        do {
            let data = try original.data()
            let converted = try ClosedRange<String>(data: data)
            #expect(converted == original, "ClosedRange 转换失败")
        } catch {
            #expect(Bool(false), "UUID 转换抛出错误: \(error)")
        }
    }
}
