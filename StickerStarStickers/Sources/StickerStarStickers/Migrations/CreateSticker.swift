import Fluent

/// A migration that creates the `"stickers"` table in the database with fields for ID, name, and userID.
struct CreateSticker: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("stickers")
            .id()
            .field("name", .string, .required)
            .field("userID", .uuid, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("stickers").delete()
    }
}
