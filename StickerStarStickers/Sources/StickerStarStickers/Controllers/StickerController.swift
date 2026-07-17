import Fluent
import Vapor

/// A controller that manages routes related to stickers, including creating, retrieving, updating, deleting, and trading stickers.
struct StickerController: RouteCollection {
    /// Boots the routes for the StickerController, registering the appropriate handlers for each route.
    ///
    /// The routes include:
    /// - `GET /`: Retrieves a list of all stickers.
    /// - `GET /:stickerID`: Retrieves a specific sticker by its ID.
    /// - `POST /`: Creates a new sticker (requires an authentication token provided by the Users microservice).
    /// - `DELETE /:stickerID`: Deletes a specific sticker by its ID (requires an authentication token provided by the Users microservice).
    /// - `PUT /:stickerID`: Updates an existing sticker by its ID (requires an authentication token provided by the Users microservice).
    /// - `GET /user/:userID`: Retrieves all stickers associated with a specific user by their ID.
    /// - `POST /trade`: Initiates a trade between two stickers (requires an authentication token provided by the Users microservice).
    ///
    /// ## Middleware
    /// 
    /// Routes that require authentication are protected by the ``UserAuthMiddleware``,
    /// which verifies the presence and validity of an authentication token provided by the Users microservice by making a request to the Users microservice.
    ///
    /// The hostname of the Users microservice is determined by the `AUTH_HOSTNAME` environment variable, defaulting to `localhost` if not set.
    ///
    /// - Parameter routes: The Vapor routes builder to register the routes on.
    func boot(routes: any RoutesBuilder) throws {
        routes.get(use: self.index)
        routes.get(":stickerID", use: self.get)
        routes.get("user", ":userID", use: self.getUsersStickers)
        
        let authHostname =
            if let host = Environment.get("AUTH_HOSTNAME") {
                host
            } else {
                "localhost"
            }
        let authGroup = routes.grouped(UserAuthMiddleware(authHostname: authHostname))
        authGroup.post(use: self.create)
        authGroup.delete(":stickerID", use: self.delete)
        authGroup.put(":stickerID", use: self.update)
        authGroup.post("trade", use: self.trade)
    }

    /// Handles the `GET /stickers` route,
    /// retrieving a list of all stickers from the database and returning them as an array of ``StickerDTO`` objects.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: An array of ``StickerDTO`` objects representing all stickers in the database.
    @Sendable
    func index(req: Request) async throws -> [StickerDTO] {
        try await Sticker.query(on: req.db).all().map { $0.toDTO() }
    }

    /// Handles the `GET /stickers/:stickerID` route,
    /// retrieving a specific sticker by its ID from the database and returning it as a ``StickerDTO`` object.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: A ``StickerDTO`` object representing the sticker with the specified ID.
    @Sendable
    func get(req: Request) async throws -> StickerDTO {
        guard let sticker = try await Sticker.find(req.parameters.get("stickerID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return sticker.toDTO()
    }

    /// Handles the `POST /stickers` route,
    /// creating a new sticker in the database with the provided data and returning it as a ``StickerDTO`` object.
    ///
    /// The request must include an `Authorization` header with a valid token,
    /// which is verified by the ``UserAuthMiddleware`` before reaching this handler.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: A ``StickerDTO`` object representing the newly created sticker.
    @Sendable
    func create(req: Request) async throws -> StickerDTO {
        let data = try req.content.decode(StickerData.self)
        let user = try req.auth.require(User.self)
        let sticker = Sticker(
            name: data.name,
            userID: user.id
        )
        try await sticker.save(on: req.db)
        return sticker.toDTO()
    }

    /// Handles the `DELETE /stickers/:stickerID` route, deleting a specific sticker by its ID from the database.
    ///
    /// The request must include an `Authorization` header with a valid token,
    /// which is verified by the ``UserAuthMiddleware`` before reaching this handler.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: An HTTP status indicating the result of the deletion operation.
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let sticker = try await Sticker.find(req.parameters.get("stickerID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await sticker.delete(on: req.db)
        return .noContent
    }

    /// Handles the `PUT /stickers/:stickerID` route,
    /// updating an existing sticker by its ID in the database with the provided data and returning it as a ``StickerDTO`` object.
    ///
    /// The request must include an `Authorization` header with a valid token,
    /// which is verified by the ``UserAuthMiddleware`` before reaching this handler.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: A ``StickerDTO`` object representing the updated sticker.
    @Sendable
    func update(req: Request) async throws -> StickerDTO {
        let updateData = try req.content.decode(StickerData.self)
        let user = try req.auth.require(User.self)
        guard let sticker = try await Sticker.find(req.parameters.get("stickerID"), on: req.db) else {
            throw Abort(.notFound)
        }
        sticker.name = updateData.name
        sticker.userID = user.id
        try await sticker.save(on: req.db)
        return sticker.toDTO()
    }

    /// Handles the `GET /stickers/user/:userID` route,
    /// retrieving all stickers associated with a specific user by their ID from the database
    /// and returning them as an array of ``StickerDTO`` objects.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: An array of ``StickerDTO`` objects representing all stickers associated with the specified user ID.
    @Sendable
    func getUsersStickers(req: Request) async throws -> [StickerDTO] {
        let userID = try req.parameters.require("userID", as: UUID.self)
        return try await Sticker.query(on: req.db).filter(\.$userID == userID).all().map { $0.toDTO() }
    }

    /// Handles the `POST /stickers/trade` route, initiating a trade between two stickers by swapping their user IDs in the database.
    ///
    /// ## Trade Process
    ///
    /// The request body must contain a valid ``TradeData`` object specifying the IDs of the offered and requested stickers.
    /// If everything is valid, the user IDs of the two stickers are swapped, effectively trading ownership of the stickers.
    ///
    /// The request must include an `Authorization` header with a valid token,
    /// which is verified by the ``UserAuthMiddleware`` before reaching this handler.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: An HTTP status indicating the result of the trade operation.
    @Sendable
    func trade(req: Request) async throws -> HTTPStatus {
        let tradeData = try req.content.decode(TradeData.self)
        let user = try req.auth.require(User.self)

        guard let offeredSticker = try await Sticker.find(tradeData.offeredStickerID, on: req.db) else {
            throw Abort(.notFound, reason: "Offered sticker not found")
        }

        // Ensure the offered sticker belongs to the authenticated user
        guard offeredSticker.userID == user.id else {
            throw Abort(.forbidden, reason: "You do not own the offered sticker")
        }

        guard let requestedSticker = try await Sticker.find(tradeData.requestedStickerID, on: req.db) else {
            throw Abort(.notFound, reason: "Requested sticker not found")
        }

        // Perform the trade by swapping the userIDs of the stickers
        let tempUserID = offeredSticker.userID
        offeredSticker.userID = requestedSticker.userID
        requestedSticker.userID = tempUserID

        try await offeredSticker.save(on: req.db)
        try await requestedSticker.save(on: req.db)

        return .ok
    }
}

/// A DTO representing the data required to create or update a sticker, including its name.
struct StickerData: Content {
    let name: String
}

/// A DTO representing the data required to initiate a trade between two stickers, including the offered and requested sticker IDs.
struct TradeData: Content {
    /// The ID of the sticker being offered by the trader for trade.
    let offeredStickerID: UUID
    /// The ID of the sticker being requested by the trader in exchange for the offered sticker.
    let requestedStickerID: UUID
}
