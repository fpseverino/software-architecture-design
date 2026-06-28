import Vapor

struct UserController: RouteCollection {
    let userServiceURL: String
    let stickersServiceURL: String
    
    init(userServiceHostname: String, stickersServiceHostname: String) {
        userServiceURL = "http://\(userServiceHostname):8081"
        stickersServiceURL = "http://\(stickersServiceHostname):8082"
    }
    
    func boot(routes: any RoutesBuilder) throws {
        let routeGroup = routes.grouped("api", "users")
        routeGroup.get(use: self.index)
        routeGroup.get(":userID", use: self.get)
        routeGroup.post(use: self.create)
        routeGroup.post("login", use: self.login)
        routeGroup.get(":userID", "stickers", use: self.getStickers)
    }

    @Sendable
    func index(req: Request) async throws -> ClientResponse {
        try await req.client.get("\(userServiceURL)/users")
    }

    @Sendable
    func get(req: Request) async throws -> ClientResponse {
        let id = try req.parameters.require("userID", as: UUID.self)
        return try await req.client.get("\(userServiceURL)/users/\(id)")
    }

    @Sendable
    func create(req: Request) async throws -> ClientResponse {
        try await req.client.post("\(userServiceURL)/users") { createRequest in
            try createRequest.content.encode(req.content.decode(CreateUserData.self))
        }
    }

    @Sendable
    func login(req: Request) async throws -> ClientResponse {
        try await req.client.post("\(userServiceURL)/auth/login") { loginRequest in
            guard let authHeader = req.headers[.authorization].first else {
                throw Abort(.unauthorized)
            }
            loginRequest.headers.add(name: .authorization, value: authHeader)
        }
    }

    @Sendable
    func getStickers(req: Request) async throws -> ClientResponse {
        let userID = try req.parameters.require("userID", as: UUID.self)
        return try await req.client.get("\(stickersServiceURL)/user/\(userID)")
    }
}

struct CreateUserData: Content {
    let username: String
    let password: String
}
