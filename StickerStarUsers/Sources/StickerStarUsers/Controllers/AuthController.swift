import Fluent
import Vapor
import Redis

/// A controller that handles authentication-related routes, including login and token-based authentication.
///
/// ## Redis
///
/// The controller uses Redis to store and retrieve authentication tokens,
/// allowing for quick validation of tokens without needing to query the database.
/// This approach improves performance and scalability,
/// especially in distributed systems where multiple instances of the application may be running.
struct AuthController: RouteCollection {
    /// Boots the routes for the authentication controller, registering the necessary endpoints for login and token-based authentication.
    /// 
    /// The routes include:
    /// - `POST /auth/login`: Authenticates a user using basic authentication and returns an authentication token.
    /// - `POST /auth/authenticate`: Authenticates a user using a provided token and returns the associated user information.
    ///
    /// - Parameter routes: The Vapor routes builder to register the routes on.
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")

        let basicMiddleware = User.authenticator()
        let basicAuth = auth.grouped(basicMiddleware)
        basicAuth.post("login", use: self.login)

        auth.post("authenticate", use: self.authenticate)
    }

    /// Handles the `POST /auth/login` route, authenticating a user using basic authentication and returning an authentication token.
    ///
    /// The request must include an `Authorization` header with a valid basic authentication string,
    /// composed of the user's username and password encoded in Base64,
    /// which is then used by the `ModelAuthenticatable` protocol to authenticate the user.
    ///
    /// ## Redis
    ///
    /// The generated token is stored in Redis with the token string as the key and the ``Token`` object as the value.
    /// This allows for quick token validation in subsequent requests without needing to query the database.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: A ``Token`` object representing the authenticated user's token.
    @Sendable
    func login(req: Request) async throws -> Token {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        try await req.redis.set(RedisKey(token.tokenString), toJSON: token)
        return token
    }

    /// Handles the `POST /auth/authenticate` route,
    /// authenticating a user using a provided token and returning the associated user information.
    ///
    /// The request must include a JSON body with the token string,
    /// which is then used to retrieve the associated ``Token`` object from Redis.
    /// If the token is valid, the associated user is retrieved from the database and returned as a ``UserDTO`` object.
    /// 
    /// ## Redis
    ///
    /// The token is retrieved from Redis using the token string provided in the request body,
    /// allowing for quick validation without needing to query the database.
    /// If the token exists, the associated user is fetched from the database and returned as a ``UserDTO`` object.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: A ``UserDTO`` object representing the authenticated user.
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

/// A DTO representing the data required for authentication, specifically the token string.
struct AuthenticateData: Content {
    let token: String
}
