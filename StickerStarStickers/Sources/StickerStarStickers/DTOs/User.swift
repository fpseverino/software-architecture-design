import Foundation
import Vapor

/// A DTO representing an `Authenticatable` user (see `Vapor.Authenticatable` and the StickerStarUsers service),
/// including their ID and username.
struct User: Content {
    let id: UUID
    let username: String

    init(id: UUID, username: String) {
        self.id = id
        self.username = username
    }
}

extension User: Authenticatable {}
