import Vapor

struct UserAuthMiddleware: AsyncMiddleware {
    let authHostname: String

    init(authHostname: String) {
        self.authHostname = authHostname
    }

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

struct AuthenticateData: Content {
    let token: String
}
