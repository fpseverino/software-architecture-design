import Vapor

func routes(_ app: Application) throws {
    let usersHostname: String
    let stickersHostname: String

    if let users = Environment.get("USERS_HOSTNAME") {
        usersHostname = users
    } else {
        usersHostname = "localhost"
    }

    if let stickers = Environment.get("STICKERS_HOSTNAME") {
        stickersHostname = stickers
    } else {
        stickersHostname = "localhost"
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
