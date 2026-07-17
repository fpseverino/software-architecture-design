import Vapor

/// A middleware that authenticates users by verifying their bearer token with the authentication service.
///
/// The middleware checks for the presence of a bearer token in the request headers,
/// sends it to the authentication (StickerStarUsers) service for validation, and logs in the user if the token is valid.
/// If the token is missing or invalid, the middleware responds with an unauthorized error.
struct UserAuthMiddleware: AsyncMiddleware {
    /// The hostname of the authentication service (StickerStarUsers) to which the middleware will send the token for validation.
    let authHostname: String

    init(authHostname: String) {
        self.authHostname = authHostname
    }

    /// Responds to an incoming request by checking for a bearer token in the headers, validating it with the authentication service, and logging in the user if valid.
    ///
    /// - Parameters:
    ///   - request: The incoming Vapor request that may contain a bearer token in its headers.
    ///   - next: The next responder in the middleware chain to which the request will be passed if authentication is successful.
    /// - Throws: An `Abort` error with a status of `.unauthorized` if the token is missing or invalid, or `.internalServerError` for other errors.
    /// - Returns: A `Response` object from the next responder in the chain if authentication is successful.
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let token = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized)
        }
        let response = try await request.client.post("http://\(authHostname):8081/auth/authenticate", beforeSend: { authRequest in
            try authRequest.content.encode(AuthenticateData(token: token.token))
        })
        guard response.status == .ok else {
            if response.status == .unauthorized {
            throw Abort(.unauthorized)
            } else {
            throw Abort(.internalServerError)
            }
        }
        let user = try response.content.decode(User.self)
        request.auth.login(user)
        return try await next.respond(to: request)
    }
}

/// A DTO representing the data required to authenticate a user, including their token.
struct AuthenticateData: Content {
    let token: String
}
