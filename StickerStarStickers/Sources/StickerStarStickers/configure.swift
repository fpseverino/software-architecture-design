import NIOSSL
import Fluent
import FluentMySQLDriver
import Vapor

/// Configures the application with the specified port for the Stickers microservice and the database configuration.
/// It also registers the application's routes with the ``routes(_:)`` function and performs any necessary database migrations.
func configure(_ app: Application) async throws {
    let port =
        if let environmentPort = Environment.get("PORT") {
            Int(environmentPort) ?? 8082
        } else {
            8082
        }
    app.http.server.configuration.port = port

    app.databases.use(DatabaseConfigurationFactory.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? MySQLConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tlsConfiguration: .forClient(certificateVerification: .none)
    ), as: .mysql)

    app.migrations.add(CreateSticker())

    // register routes
    try routes(app)

    try await app.autoMigrate()
}
