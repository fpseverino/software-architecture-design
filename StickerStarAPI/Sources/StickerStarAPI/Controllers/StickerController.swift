import Vapor

/// A controller that handles the API Gateway routes for the Stickers microservice,
/// forwarding requests to the Stickers and Users microservices as needed.
struct StickerController: RouteCollection {
    /// The base URL for the Stickers microservice.
    let stickersServiceURL: String
    /// The base URL for the Users microservice.
    let userServiceURL: String

    /// Initializes a new instance of the ``StickerController`` with the specified service hostnames for the Stickers and Users microservices,
    /// constructing the appropriate service URLs for each microservice with the default ports of 8082 for Stickers and 8081 for Users.
    /// - Parameters:
    ///   - stickersServiceHostname: The hostname of the Stickers microservice.
    ///   - userServiceHostname: The hostname of the Users microservice.
    init(stickersServiceHostname: String, userServiceHostname: String) {
        stickersServiceURL = "http://\(stickersServiceHostname):8082"
        userServiceURL = "http://\(userServiceHostname):8081"
    }

    /// Boots the routes for the API Gateway ``StickerController`` on the provided routes builder, registering the appropriate HTTP methods and paths for each route.
    ///
    /// The routes include:
    /// - `GET /api/stickers`: Retrieves a list of all stickers.
    /// - `GET /api/stickers/:stickerID`: Retrieves a specific sticker by its ID.
    /// - `POST /api/stickers`: Creates a new sticker.
    /// - `PUT /api/stickers/:stickerID`: Updates an existing sticker by its ID.
    /// - `DELETE /api/stickers/:stickerID`: Deletes a specific sticker by its ID.
    /// - `GET /api/stickers/:stickerID/user`: Retrieves the user associated with a specific sticker by its ID.
    /// - `POST /api/stickers/trade`: Initiates a trade between two stickers.
    ///
    /// - Parameter routes: The Vapor routes builder to register the routes on.
    func boot(routes: any RoutesBuilder) throws {
        let stickersGroup = routes.grouped("api", "stickers")
        stickersGroup.get(use: self.index)
        stickersGroup.get(":stickerID", use: self.get)
        stickersGroup.post(use: self.create)
        stickersGroup.put(":stickerID", use: self.update)
        stickersGroup.delete(":stickerID", use: self.delete)
        stickersGroup.get(":stickerID", "user", use: self.getUser)
        stickersGroup.post("trade", use: self.trade)
    }

    /// Handles the `GET /api/stickers` route, forwarding the request to the Stickers microservice and returning its response.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: The response from the Stickers microservice.
    @Sendable
    func index(req: Request) async throws -> ClientResponse {
        try await req.client.get("\(stickersServiceURL)/")
    }

    /// Handles the `GET /api/stickers/:stickerID` route, forwarding the request to the Stickers microservice and returning its response.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: The response from the Stickers microservice.
    @Sendable
    func get(req: Request) async throws -> ClientResponse {
        let id = try req.parameters.require("stickerID", as: UUID.self)
        return try await req.client.get("\(stickersServiceURL)/\(id)")
    }

    /// Handles the `POST /api/stickers` route, forwarding the request to the Stickers microservice and returning its response.
    ///
    /// The request must include an `Authorization` header with a valid token, which is forwarded to the Stickers microservice.
    /// The request body must contain a valid ``CreateStickerData`` object.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: The response from the Stickers microservice.
    @Sendable
    func create(req: Request) async throws -> ClientResponse {
        try await req.client.post("\(stickersServiceURL)/") { createRequest in
            guard let authHeader = req.headers[.authorization].first else {
                throw Abort(.unauthorized)
            }
            createRequest.headers.add(name: .authorization, value: authHeader)
            try createRequest.content.encode(req.content.decode(CreateStickerData.self))
        }
    }

    /// Handles the `PUT /api/stickers/:stickerID` route, forwarding the request to the Stickers microservice and returning its response.
    ///
    /// The request must include an `Authorization` header with a valid token, which is forwarded to the Stickers microservice.
    /// The request body must contain a valid ``CreateStickerData`` object.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: The response from the Stickers microservice.
    @Sendable
    func update(req: Request) async throws -> ClientResponse {
        let stickerID = try req.parameters.require("stickerID", as: UUID.self)
        return try await req.client.put("\(stickersServiceURL)/\(stickerID)") { updateRequest in
            guard let authHeader = req.headers[.authorization].first else {
                throw Abort(.unauthorized)
            }
            updateRequest.headers.add(name: .authorization, value: authHeader)
            try updateRequest.content.encode(req.content.decode(CreateStickerData.self))
        }
    }

    /// Handles the `DELETE /api/stickers/:stickerID` route, forwarding the request to the Stickers microservice and returning its response.
    ///
    /// The request must include an `Authorization` header with a valid token, which is forwarded to the Stickers microservice.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: The response from the Stickers microservice.
    @Sendable
    func delete(req: Request) async throws -> ClientResponse {
        let stickerID = try req.parameters.require("stickerID", as: UUID.self)
        return try await req.client.delete("\(stickersServiceURL)/\(stickerID)") { deleteRequest in
            guard let authHeader = req.headers[.authorization].first else {
                throw Abort(.unauthorized)
            }
            deleteRequest.headers.add(name: .authorization, value: authHeader)
        }
    }

    /// Handles the `GET /api/stickers/:stickerID/user` route, forwarding the request to the Stickers microservice to retrieve the sticker's user ID,
    /// and then forwarding the request to the Users microservice to retrieve the user information.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: The response from the Users microservice.
    @Sendable
    func getUser(req: Request) async throws -> ClientResponse {
        let stickerID = try req.parameters.require("stickerID", as: UUID.self)
        let response = try await req.client.get("\(stickersServiceURL)/\(stickerID)")
        let sticker = try response.content.decode(Sticker.self)
        return try await req.client.get("\(userServiceURL)/users/\(sticker.userID)")
    }

    /// Handles the `POST /api/stickers/trade` route, forwarding the request to the Stickers microservice to initiate a trade between two stickers.
    ///
    /// The request must include an `Authorization` header with a valid token, which is forwarded to the Stickers microservice.
    /// The request body must contain a valid ``TradeData`` object.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: The response from the Stickers microservice.
    @Sendable
    func trade(req: Request) async throws -> ClientResponse {
        return try await req.client.post("\(stickersServiceURL)/trade") { tradeRequest in
            guard let authHeader = req.headers[.authorization].first else {
                throw Abort(.unauthorized)
            }
            tradeRequest.headers.add(name: .authorization, value: authHeader)
            try tradeRequest.content.encode(req.content.decode(TradeData.self))
        }
    }
}

/// A DTO representing the data required to create a new sticker, including its name.
struct CreateStickerData: Content {
    let name: String
}

/// A DTO representing the data required to initiate a trade between two stickers, including the offered and requested sticker IDs.
struct TradeData: Content {
    /// The ID of the sticker being offered by the trader for trade.
    let offeredStickerID: UUID
    /// The ID of the sticker being requested by the trader in exchange for the offered sticker.
    let requestedStickerID: UUID
}
