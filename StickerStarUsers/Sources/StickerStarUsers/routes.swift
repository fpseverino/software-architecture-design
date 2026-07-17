import Fluent
import Vapor

/// Registers the ``UserController`` and ``AuthController`` routes on the provided application.
/// - Parameter app: The application to register routes on.
func routes(_ app: Application) throws {
    try app.register(collection: UserController())
    try app.register(collection: AuthController())
}
