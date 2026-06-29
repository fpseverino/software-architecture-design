import Fluent
import Vapor

struct StickerController: RouteCollection {
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

    @Sendable
    func index(req: Request) async throws -> [StickerDTO] {
        try await Sticker.query(on: req.db).all().map { $0.toDTO() }
    }

    @Sendable
    func get(req: Request) async throws -> StickerDTO {
        guard let sticker = try await Sticker.find(req.parameters.get("stickerID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return sticker.toDTO()
    }

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

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let sticker = try await Sticker.find(req.parameters.get("stickerID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await sticker.delete(on: req.db)
        return .noContent
    }

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

    @Sendable
    func getUsersStickers(req: Request) async throws -> [StickerDTO] {
        let userID = try req.parameters.require("userID", as: UUID.self)
        return try await Sticker.query(on: req.db).filter(\.$userID == userID).all().map { $0.toDTO() }
    }

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

struct StickerData: Content {
    let name: String
}

struct TradeData: Content {
    let offeredStickerID: UUID
    let requestedStickerID: UUID
}
