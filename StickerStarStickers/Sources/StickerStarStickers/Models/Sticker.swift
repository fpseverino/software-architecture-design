import Fluent
import struct Foundation.UUID

/// A model representing a sticker in the database, including its ID, name, and the ID of the user who owns it.
final class Sticker: Model, @unchecked Sendable {
    /// The name of the database table that this model represents.
    static let schema = "stickers"
    
    /// The unique identifier of the sticker used in the Stickers microservice's database.
    @ID(key: .id)
    var id: UUID?

    /// The name of the sticker.
    @Field(key: "name")
    var name: String

    /// The ID of the user who owns the sticker in the Users microservice's database.
    @Field(key: "userID")
    var userID: UUID

    init() { }

    init(id: UUID? = nil, name: String, userID: UUID) {
        self.id = id
        self.name = name
        self.userID = userID
    }
    
    /// Converts the model to a ``StickerDTO`` for use in API responses,
    /// providing a layer of abstraction and security by not exposing internal database models directly.
    /// - Returns: A ``StickerDTO`` representing the sticker.
    func toDTO() -> StickerDTO {
        .init(
            id: self.id,
            name: self.$name.value,
            userID: self.$userID.value
        )
    }
}
