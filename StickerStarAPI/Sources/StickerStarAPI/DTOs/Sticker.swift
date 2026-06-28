import Vapor

struct Sticker: Content, Sendable {
    var id: UUID?
    var name: String
    var userID: UUID

    init(name: String, userID: UUID) {
        self.name = name
        self.userID = userID
    }
}
