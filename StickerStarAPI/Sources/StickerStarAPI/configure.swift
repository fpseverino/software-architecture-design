import Vapor

/// Configures the API Gateway application, including registering its routes with the ``routes(_:)`` function.
func configure(_ app: Application) async throws {
    // register routes
    try routes(app)
}
