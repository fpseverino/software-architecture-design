import Foundation
import Vapor

struct User: Content {
    let id: UUID
    let username: String

    init(id: UUID, username: String) {
        self.id = id
        self.username = username
    }
}

extension User: Authenticatable {}
