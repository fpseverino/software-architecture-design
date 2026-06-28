import Vapor

/// configures your application
func configure(_ app: Application) async throws {
    // register routes
    try routes(app)
}
