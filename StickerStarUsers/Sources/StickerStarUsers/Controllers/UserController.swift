import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")

        users.get(use: self.index)
        users.post(use: self.create)
        users.group(":userID") { user in
            user.get(use: self.get)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [UserDTO] {
        try await User.query(on: req.db).all().map { $0.toDTO() }
    }

    @Sendable
    func create(req: Request) async throws -> UserDTO {
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password)

        try await user.save(on: req.db)
        return user.toDTO()
    }

    @Sendable
    func get(req: Request) async throws -> UserDTO {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }

        return user.toDTO()
    }
}
