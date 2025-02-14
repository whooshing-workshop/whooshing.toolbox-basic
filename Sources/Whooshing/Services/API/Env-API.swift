import Foundation

extension API {
    struct ServicePara {
        let authenticationURL: URL
    }
}

extension API.ServicePara: Env.Template {
    static var envs: [String : Env.Types] { ["authentication_url": .url] }
    init() { self.authenticationURL = URL(string: "https://example.com")! }
    init(data: [String : Any]) {
        self.authenticationURL = data["authentication_url"] as! URL
    }
}
