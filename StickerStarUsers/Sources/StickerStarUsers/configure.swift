import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import Redis

/// Configures the application with the specified port for the Users microservice, the database configuration, and the Redis configuration.
/// It also registers the application's routes with the ``routes(_:)`` function and performs any necessary database migrations.
func configure(_ app: Application) async throws {
    let port =
        if let environmentPort = Environment.get("PORT") {
            Int(environmentPort) ?? 8081
        } else {
            8081
        }
    app.http.server.configuration.port = port

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    app.migrations.add(CreateUser())

    let redisHostname =
        if let redisEnvironmentHostname = Environment.get("REDIS_HOSTNAME") {
            redisEnvironmentHostname
        } else {
            "localhost"
        }
    app.redis.configuration = try RedisConfiguration(hostname: redisHostname)

    // register routes
    try routes(app)

    try await app.autoMigrate()
}
