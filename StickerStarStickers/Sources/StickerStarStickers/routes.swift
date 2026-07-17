import Fluent
import Vapor

/// Registers the ``StickerController`` routes on the provided application.
/// - Parameter app: The application to register routes on.
func routes(_ app: Application) throws {
    try app.register(collection: StickerController())
}
