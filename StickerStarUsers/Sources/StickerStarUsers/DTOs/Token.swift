import Fluent
import Foundation
import Vapor

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
    static func generate(for user: User) throws -> Token {
        let random = [UInt8].random(count: 32)
        return try Token(tokenString: random.base64, userID: user.requireID())
    }
}
