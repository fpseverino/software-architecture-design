import Fluent
import struct Foundation.UUID

final class Sticker: Model, @unchecked Sendable {
    static let schema = "stickers"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "userID")
    var userID: UUID

    init() { }

    init(id: UUID? = nil, name: String, userID: UUID) {
        self.id = id
        self.name = name
        self.userID = userID
    }
    
    func toDTO() -> StickerDTO {
        .init(
            id: self.id,
            name: self.$name.value,
            userID: self.$userID.value
        )
    }
}
