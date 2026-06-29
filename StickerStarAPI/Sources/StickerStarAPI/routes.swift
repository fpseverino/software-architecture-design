import Vapor

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
