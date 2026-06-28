import Vapor

struct StickerController: RouteCollection {
    let stickersServiceURL: String
    let userServiceURL: String

    init(stickersServiceHostname: String, userServiceHostname: String) {
        stickersServiceURL = "http://\(stickersServiceHostname):8082"
        userServiceURL = "http://\(userServiceHostname):8081"
    }

    func boot(routes: any RoutesBuilder) throws {
        let stickersGroup = routes.grouped("api", "stickers")
        stickersGroup.get(use: self.index)
        stickersGroup.get(":stickerID", use: self.get)
        stickersGroup.post(use: self.create)
        stickersGroup.put(":stickerID", use: self.update)
        stickersGroup.delete(":stickerID", use: self.delete)
        stickersGroup.get(":stickerID", "user", use: self.getUser)
    }

    @Sendable
    func index(req: Request) async throws -> ClientResponse {
        try await req.client.get("\(stickersServiceURL)/")
    }

    @Sendable
    func get(req: Request) async throws -> ClientResponse {
        let id = try req.parameters.require("stickerID", as: UUID.self)
        return try await req.client.get("\(stickersServiceURL)/\(id)")
    }

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

    @Sendable
    func getUser(req: Request) async throws -> ClientResponse {
        let stickerID = try req.parameters.require("stickerID", as: UUID.self)
        let response = try await req.client.get("\(stickersServiceURL)/\(stickerID)")
        let sticker = try response.content.decode(Sticker.self)
        return try await req.client.get("\(userServiceURL)/users/\(sticker.userID)")
    }
}

struct CreateStickerData: Content {
    let name: String
}
