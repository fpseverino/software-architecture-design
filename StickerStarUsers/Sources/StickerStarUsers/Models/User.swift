import Fluent
import struct Foundation.UUID
import Vapor

final class User: Model, @unchecked Sendable, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "password")
    var password: String

    init() { }

    init(id: UUID? = nil, username: String, password: String) {
        self.id = id
        self.username = username
        self.password = password
    }
    
    func toDTO() -> UserDTO {
        .init(
            id: self.id,
            username: self.$username.value
        )
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey: KeyPath<User, FieldProperty<User, String>> = \User.$username
    static let passwordHashKey: KeyPath<User, FieldProperty<User, String>> = \User.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
