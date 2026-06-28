@testable import StickerStarStickers
import VaporTesting
import Testing
import Fluent

@Suite("App Tests with DB", .serialized)
struct StickerStarStickersTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await app.autoRevert()
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
    
    @Test("Getting all the Stickers")
    func getAllStickers() async throws {
        try await withApp { app in
            let sampleStickers = [Sticker(name: "sample1", userID: UUID()), Sticker(name: "sample2", userID: UUID())]
            try await sampleStickers.create(on: app.db)
            
            try await app.testing().test(.GET, "", afterResponse: { res async throws in
                #expect(res.status == .ok)
                #expect(try
                    res.content.decode([StickerDTO].self).sorted(by: { ($0.name ?? "") < ($1.name ?? "") }) ==
                    sampleStickers.map { $0.toDTO() }.sorted(by: { ($0.name ?? "") < ($1.name ?? "") })
                )
            })
        }
    }
    
    @Test("Creating a Sticker")
    func createSticker() async throws {
        let newDTO = StickerData(name: "test")
        
        try await withApp { app in
            try await app.testing().test(.POST, "", beforeRequest: { req in
                try req.content.encode(newDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let models = try await Sticker.query(on: app.db).all()
                #expect(models.map({ $0.toDTO().name }) == [newDTO.name])
            })
        }
    }
    
    @Test("Deleting a Sticker")
    func deleteSticker() async throws {
        let testStickers = [Sticker(name: "test1", userID: UUID()), Sticker(name: "test2", userID: UUID())]
        
        try await withApp { app in
            try await testStickers.create(on: app.db)
            
            try await app.testing().test(.DELETE, "\(testStickers[0].requireID())", afterResponse: { res async throws in
                #expect(res.status == .noContent)
                let model = try await Sticker.find(testStickers[0].id, on: app.db)
                #expect(model == nil)
            })
        }
    }
}

extension StickerDTO: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}
