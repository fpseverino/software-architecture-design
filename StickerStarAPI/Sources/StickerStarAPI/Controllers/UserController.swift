import Vapor

/// A controller that handles user-related routes in the API Gateway application,
/// forwarding requests to the Users and Stickers microservices.
struct UserController: RouteCollection {
    /// The base URL for the Users microservice.
    let userServiceURL: String
    /// The base URL for the Stickers microservice.
    let stickersServiceURL: String
    
    /// Initializes a new instance of the ``UserController`` with the specified service hostnames for the Users and Stickers microservices,
    /// constructing the appropriate service URLs for each microservice with the default ports of 8081 for Users and 8082 for Stickers.
    /// - Parameters:
    ///   - userServiceHostname: The hostname of the Users microservice.
    ///   - stickersServiceHostname: The hostname of the Stickers microservice.
    init(userServiceHostname: String, stickersServiceHostname: String) {
        userServiceURL = "http://\(userServiceHostname):8081"
        stickersServiceURL = "http://\(stickersServiceHostname):8082"
    }
    
    /// Boots the routes for the API Gateway ``UserController`` on the provided routes builder, registering the appropriate HTTP methods and paths for each route.
    ///
    /// The routes include:
    /// - `GET /api/users`: Retrieves a list of all users.
    /// - `GET /api/users/:userID`: Retrieves a specific user by their ID.
    /// - `POST /api/users`: Creates a new user.
    /// - `POST /api/users/login`: Authenticates a user and returns a token to use for authenticated requests.
    /// - `GET /api/users/:userID/stickers`: Retrieves all stickers associated with a specific user by their ID.
    ///
    /// - Parameter routes: The Vapor routes builder to register the routes on.
    func boot(routes: any RoutesBuilder) throws {
        let routeGroup = routes.grouped("api", "users")
        routeGroup.get(use: self.index)
        routeGroup.get(":userID", use: self.get)
        routeGroup.post(use: self.create)
        routeGroup.post("login", use: self.login)
        routeGroup.get(":userID", "stickers", use: self.getStickers)
    }

    /// Handles the `GET /api/users` route, forwarding the request to the Users microservice and returning its response.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: The response from the Users microservice.
    @Sendable
    func index(req: Request) async throws -> ClientResponse {
        try await req.client.get("\(userServiceURL)/users")
    }

    /// Handles the `GET /api/users/:userID` route, forwarding the request to the Users microservice and returning its response.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: The response from the Users microservice.
    @Sendable
    func get(req: Request) async throws -> ClientResponse {
        let id = try req.parameters.require("userID", as: UUID.self)
        return try await req.client.get("\(userServiceURL)/users/\(id)")
    }

    /// Handles the `POST /api/users` route, forwarding the request to the Users microservice and returning its response.
    ///
    /// The request body must contain a valid ``CreateUserData`` object.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: The response from the Users microservice.
    @Sendable
    func create(req: Request) async throws -> ClientResponse {
        try await req.client.post("\(userServiceURL)/users") { createRequest in
            try createRequest.content.encode(req.content.decode(CreateUserData.self))
        }
    }

    /// Handles the `POST /api/users/login` route, forwarding the request to the Users microservice and returning its response.
    ///
    /// The request must include an `Authorization` header with a valid basic authentication token.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: The response from the Users microservice.
    @Sendable
    func login(req: Request) async throws -> ClientResponse {
        try await req.client.post("\(userServiceURL)/auth/login") { loginRequest in
            guard let authHeader = req.headers[.authorization].first else {
                throw Abort(.unauthorized)
            }
            loginRequest.headers.add(name: .authorization, value: authHeader)
        }
    }

    /// Handles the `GET /api/users/:userID/stickers` route, forwarding the request to the Stickers microservice and returning its response.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: The response from the Stickers microservice.
    @Sendable
    func getStickers(req: Request) async throws -> ClientResponse {
        let userID = try req.parameters.require("userID", as: UUID.self)
        return try await req.client.get("\(stickersServiceURL)/user/\(userID)")
    }
}

/// A DTO representing the data required to create a new user, including their username and password.
struct CreateUserData: Content {
    let username: String
    let password: String
}
