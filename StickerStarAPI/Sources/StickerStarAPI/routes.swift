import Vapor

/// Registers the routes of the API Gateway application,
/// including the ``UserController`` and ``StickerController`` routes
/// with the appropriate service hostnames for the Users and Stickers microservices.
///
/// - Parameter app: The application to register routes on.
func routes(_ app: Application) throws {
    let usersHostname =
        if let users = Environment.get("USERS_HOSTNAME") {
            users
        } else {
            "localhost"
        }

    let stickersHostname =
        if let stickers = Environment.get("STICKERS_HOSTNAME") {
            stickers
        } else {
            "localhost"
        }

    try app.register(collection: UserController(
        userServiceHostname: usersHostname,
        stickersServiceHostname: stickersHostname)
    )
    try app.register(collection: StickerController(
        stickersServiceHostname: stickersHostname,
        userServiceHostname: usersHostname)
    )
}
