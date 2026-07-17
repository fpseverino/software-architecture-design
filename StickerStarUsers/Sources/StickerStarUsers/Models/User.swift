import Fluent
import struct Foundation.UUID
import Vapor

/// A model representing a user in the database, including their ID, username, and password.
final class User: Model, @unchecked Sendable, Content {
    /// The name of the database table that this model represents.
    static let schema = "users"
    
    /// The unique identifier of the user used in the Users microservice's database.
    @ID(key: .id)
    var id: UUID?

    /// The username of the user.
    @Field(key: "username")
    var username: String

    /// The password of the user, stored as a hashed value for security.
    @Field(key: "password")
    var password: String

    init() { }

    init(id: UUID? = nil, username: String, password: String) {
        self.id = id
        self.username = username
        self.password = password
    }
    
    /// Converts the model to a ``UserDTO`` for use in API responses,
    /// providing a layer of abstraction and security by not exposing internal database models directly.
    /// - Returns: A ``UserDTO`` representing the user.
    func toDTO() -> UserDTO {
        .init(
            id: self.id,
            username: self.$username.value
        )
    }
}

extension User: ModelAuthenticatable {
    /// The key path to the username field in the `User` model, used for authentication.
    /// This allows the authentication system to retrieve the username for login purposes.
    ///
    /// This is required by the `ModelAuthenticatable` protocol to identify the user during the authentication process.
    ///
    /// > Note: The username is used as the unique identifier for authentication.
    static let usernameKey: KeyPath<User, FieldProperty<User, String>> = \User.$username
    /// The key path to the password field in the `User` model, used for authentication.
    /// This allows the authentication system to retrieve the hashed password for verification during login.
    ///
    /// This is required by the `ModelAuthenticatable` protocol to verify the user's credentials during the authentication process.
    ///
    /// > Note: The password is stored as a hashed value with Bcrypt for security,
    ///     and the authentication system will verify the provided password against this hash.
    static let passwordHashKey: KeyPath<User, FieldProperty<User, String>> = \User.$password
    
    /// Verifies the provided password against the stored hashed password for authentication.
    ///
    /// > Important: This method uses Bcrypt to securely compare the provided password with the stored hash,
    ///     ensuring that the authentication process is secure and resistant to attacks.
    ///
    /// - Parameter password: The plain-text password to verify.
    /// - Throws: An error if the verification process fails.
    /// - Returns: `true` if the password matches the stored hash, `false` otherwise.
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
