import Fluent
import Vapor
import Redis

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")

        let basicMiddleware = User.authenticator()
        let basicAuth = auth.grouped(basicMiddleware)
        basicAuth.post("login", use: self.login)

        auth.post("authenticate", use: self.authenticate)
    }

    @Sendable
    func login(req: Request) async throws -> Token {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        try await req.redis.set(RedisKey(token.tokenString), toJSON: token)
        return token
    }

    @Sendable
    func authenticate(req: Request) async throws -> UserDTO {
        let data = try req.content.decode(AuthenticateData.self)
        guard let token = try await req.redis.get(RedisKey(data.token), asJSON: Token.self) else {
            throw Abort(.unauthorized)
        }
        guard let user = try await User.query(on: req.db)
            .filter(\.$id == token.userID)
            .first()
        else {
            throw Abort(.internalServerError)
        }
        return user.toDTO()
    }
}


struct AuthenticateData: Content {
    let token: String
}
