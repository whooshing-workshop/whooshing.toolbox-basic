import Testing
@testable import DataConvertable
import Foundation

@Suite("数据转换模块-测试")
struct DataConvertableTest {
    
    @Test("字符串转换测试")
    func testStringConversion() {
        let originalString = "Hello, World!"
        do {
            let data = try originalString.dataRes.get()
            let convertedString = try String.make(data: data).get()
            #expect(convertedString == originalString)
        } catch {
            #expect(Bool(false), "字符串转换抛出错误: \(error)")
        }
    }
    
    @Test("Base64 字符串转换测试")
    func testBase64StringConversion() {
        let originalString = Base64String(Data((0..<16).map { _ in UInt8.random(in: 0...255) }).base64EncodedString())
        do {
            let data = try originalString.dataRes.get()
            let convertedString = Base64String.new(data: data)
            #expect(convertedString == originalString)
        } catch {
            #expect(Bool(false), "Base64 字符串转换抛出错误: \(error)")
        }
    }
    
    @Test("整数转换测试")
    func testIntConversion() {
        let originalInt: Int = 42
        let data = originalInt.data
        let convertedInt = Int.new(data: data)
        #expect(convertedInt == originalInt, "整数转换失败")
    }
    
    @Test("数组转换测试")
    func testArrayConversion() {
        let originalArray: [Int] = [1, 2, 3, 4, 5]
        let data = originalArray.data
        let convertedArray = [Int].new(data: data)
        #expect(convertedArray == originalArray, "数组转换失败")
    }
    
    @Test("浮点数转换测试")
    func testFloatConversion() {
        let originalFloat: Float = 3.14
        let data = originalFloat.data
        let convertedFloat = Float.new(data: data)
        #expect(convertedFloat == originalFloat, "浮点数转换失败")
    }
    
    @Test("双精度浮点数转换测试")
    func testDoubleConversion() {
        let originalDouble: Double = 3.14159265359
        let data = originalDouble.data
        let convertedDouble = Double.new(data: data)
        #expect(convertedDouble == originalDouble, "双精度浮点数转换失败")
    }
    
    @Test("字典转换测试")
    func testDictionaryConversion() {
        let originalDictionary: [String: Int] = ["one": 1, "two": 2, "three": 3]
        do {
            let data = try originalDictionary.dataRes.get()
            let convertedDictionary = try [String: Int].make(data: data).get()
            #expect(convertedDictionary == originalDictionary, "字典转换失败")
        } catch {
            #expect(Bool(false), "字典转换抛出错误: \(error)")
        }
    }
    
    @Test("Safe 字典转换测试")
    func testSafeDictionaryConversion() {
        let originalDictionary: [Int: Int] = [1: 1, 2: 2, 3: 3]
        let data = originalDictionary.data
        let convertedDictionary = [Int: Int].new(data: data)
        #expect(convertedDictionary == originalDictionary, "字典转换失败")
    }
    
    @Test("UUID 转换测试")
    func testUUIDConversion() {
        let original = UUID()
        do {
            let data = original.data
            let converted = try UUID.make(data: data).get()
            #expect(converted == original, "UUID 转换失败")
        } catch {
            #expect(Bool(false), "UUID 转换抛出错误: \(error)")
        }
    }
    
    @Test("Range 转换测试")
    func rangeConversion() {
        let original = 0..<100
        let data = original.data
        let converted = Range<Int>.new(data: data)
        #expect(converted == original, "ClosedRange 转换失败")
    }
    
    @Test("Range Throwable 转换测试")
    func rangeThrowableConversion() {
        let original = "a"..<"z"
        do {
            let data = try original.dataRes.get()
            let converted = try Range<String>.make(data: data).get()
            #expect(converted == original, "ClosedRange 转换失败")
        } catch {
            #expect(Bool(false), "UUID 转换抛出错误: \(error)")
        }
    }
    
    @Test("ClosedRange 转换测试")
    func testRangeConversion() {
        let original = 0...100
        let data = original.data
        let converted = ClosedRange<Int>.new(data: data)
        #expect(converted == original, "ClosedRange 转换失败")
    }
    
    @Test("ClosedRange Throwable 转换测试")
    func testRangeThrowableConversion() {
        let original = "a"..."z"
        do {
            let data = try original.dataRes.get()
            let converted = try ClosedRange<String>.make(data: data).get()
            #expect(converted == original, "ClosedRange 转换失败")
        } catch {
            #expect(Bool(false), "UUID 转换抛出错误: \(error)")
        }
    }
}
