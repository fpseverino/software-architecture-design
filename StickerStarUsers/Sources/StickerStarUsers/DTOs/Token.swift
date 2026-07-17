import Fluent
import Foundation
import Vapor

/// A DTO representing an authentication token, including its ID, token string, and associated user ID.
struct Token: Content, Sendable {
    var id: UUID?
    var tokenString: String
    var userID: UUID

    init(tokenString: String, userID: UUID) {
        self.tokenString = tokenString
        self.userID = userID
    }
}

extension Token {
    /// Generates a new ``Token`` for the given ``User``, creating a random token string and associating it with the user's ID.
    /// - Parameter user: The ``User`` for whom the token is being generated.
    /// - Returns: A new ``Token`` instance associated with the provided user.
    static func generate(for user: User) throws -> Token {
        let random = [UInt8].random(count: 32)
        return try Token(tokenString: random.base64, userID: user.requireID())
    }
}
