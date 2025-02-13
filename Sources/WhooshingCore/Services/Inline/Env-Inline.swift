#if INLINE

import Foundation

extension Inline {
    struct ServicePara {
        let serviceID: UUID
    }
}

extension Inline.ServicePara: Env.Template {
    static var envs: [String : Env.Types] { ["service_id": .uuid] }
    init() { self.serviceID = .init() }
    init(data: [String : Any]) {
        self.serviceID = data["service_id"] as! UUID
    }
}

#endif
