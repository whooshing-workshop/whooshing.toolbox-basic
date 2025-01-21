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
    
    @Test("整数转换测试")
    func testIntConversion() {
        let originalInt: Int = 42
        let data = originalInt.data()
        let convertedInt = Int(data: data)
        #expect(convertedInt == originalInt, "整数转换失败")
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
    
    @Test("空字典转换测试")
    func testEmptyDictionaryConversion() {
        let originalDictionary: [String: Int] = [:]
        do {
            let data = try originalDictionary.data()
            let convertedDictionary = try [String: Int](data: data)
            #expect(convertedDictionary == originalDictionary, "字典转换失败")
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
