import Fluent
import Vapor

/// A controller that handles user-related routes, including listing users, creating a new user, and retrieving a specific user by ID.
struct UserController: RouteCollection {
    /// Boots the routes for the user controller, registering the necessary endpoints for user operations.
    ///
    /// The routes include:
    /// - `GET /users`: Retrieves a list of all users.
    /// - `POST /users`: Creates a new user.
    /// - `GET /users/:userID`: Retrieves a specific user by their ID.
    ///
    /// - Parameter routes: The Vapor routes builder to register the routes on.
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")

        users.get(use: self.index)
        users.post(use: self.create)
        users.group(":userID") { user in
            user.get(use: self.get)
        }
    }

    /// Handles the `GET /users` route,
    /// retrieving a list of all users from the database and returning them as an array of ``UserDTO`` objects.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: An array of ``UserDTO`` objects representing all users in the database.
    @Sendable
    func index(req: Request) async throws -> [UserDTO] {
        try await User.query(on: req.db).all().map { $0.toDTO() }
    }

    /// Handles the `POST /users` route,
    /// creating a new user in the database based on the provided request data and returning the created user as a ``UserDTO`` object.
    ///
    /// The request must include a JSON body with the user's username and password.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: A ``UserDTO`` object representing the newly created user.
    @Sendable
    func create(req: Request) async throws -> UserDTO {
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password)

        try await user.save(on: req.db)
        return user.toDTO()
    }

    /// Handles the `GET /users/:userID` route,
    /// retrieving a specific user by their ID from the database and returning it as a ``UserDTO`` object.
    ///
    /// - Parameter req: The incoming Vapor request.
    /// - Returns: A ``UserDTO`` object representing the user with the specified ID.
    @Sendable
    func get(req: Request) async throws -> UserDTO {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }

        return user.toDTO()
    }
}
