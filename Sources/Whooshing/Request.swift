import Vapor
import Cryptos
import ErrorHandle
import DataConvertable
import NIO
import Logging

extension Client {
    
}

enum RelayRequest {
    fileprivate enum Err: String, ErrList {
        var domain: String { "woo.sys.relay.request.err" }
        case relayParseFailed = "中继转送解析失败"
    }
    
    static func relayDataHandle(_ request: Data) throws -> Data? {
        guard let req = String(data: request, encoding: .utf8) else { return nil }
        let relayReq = try relayRequestModify(data: req)
        return relayReq.data(using: .utf8)
    }
    
    private static func relayRequestModify(data: String) throws -> String {
        // 分割请求头和主体
        let components = data.components(separatedBy: "\r\n\r\n")
        guard components.count >= 2 else { throw Err.relayParseFailed.d("非完整的中继 HTTP 请求", 10066, (#file, #line)) }
        var headers = components[0].components(separatedBy: "\r\n")
        let body = components.dropFirst().joined(separator: "\r\n\r\n")
        guard headers.count >= 1 else { throw Err.relayParseFailed.d("中继 HTTP 请求的格式不正确", 10067, (#file, #line)) }
        let separator = "/whooshing-relay"
        let requestLine = headers[0].components(separatedBy: " ")
        guard requestLine.count == 3 else { throw Err.relayParseFailed.d("中继 HTTP 请求的第一行 Header 格式不正确", 10067, (#file, #line)) }
        
        // 修改请求 URI
        let method = requestLine[0]
        let relayUri = requestLine[1].components(separatedBy: separator)
        guard relayUri.count == 2 else { throw Err.relayParseFailed.d("中继 HTTP 请求的 URI 格式不正确", 10068, (#file, #line)) }
        guard relayUri[0].count > 1 else { throw Err.relayParseFailed.d("中继 HTTP 请求的 URI 格式不正确", 10069, (#file, #line)) }
        let newHost = relayUri[0].dropFirst()
        let newURI = relayUri[1]
        let httpVersion = requestLine[2]
        headers[0] = "\(method) \(newURI) \(httpVersion)"
        
        // 修改 Header
        for (index, header) in headers.enumerated() {
            if header.lowercased().hasPrefix("host:") {
                headers[index] = "Host: \(newHost)"
                break
            }
        }
        
        // 重组请求头和主体
        let newRequest = headers.joined(separator: "\r\n") + "\r\n\r\n" + body
        return newRequest
    }
}
