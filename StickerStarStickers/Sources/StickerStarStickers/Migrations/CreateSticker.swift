import Fluent

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
