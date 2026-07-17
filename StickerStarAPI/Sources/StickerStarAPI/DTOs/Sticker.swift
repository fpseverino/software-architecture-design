import Vapor

/// A DTO representing a sticker, including its ID, name, and the ID of the user who owns it.
struct Sticker: Content, Sendable {
    /// The unique identifier of the sticker used in the Stickers microservice's database.
    var id: UUID?
    /// The name of the sticker.
    var name: String
    /// The ID of the user who owns the sticker in the Users microservice's database.
    var userID: UUID

    init(name: String, userID: UUID) {
        self.name = name
        self.userID = userID
    }
}
