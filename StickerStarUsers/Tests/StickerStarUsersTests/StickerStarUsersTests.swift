@testable import StickerStarUsers
import VaporTesting
import Testing
import Fluent

@Suite("App Tests with DB", .serialized)
struct StickerStarUsersTests {
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
    
    @Test("Getting all the Users")
    func getAllUsers() async throws {
        try await withApp { app in
            let sampleUsers = [User(username: "sample1", password: "password1"), User(username: "sample2", password: "password2")]
            try await sampleUsers.create(on: app.db)
            
            try await app.testing().test(.GET, "users", afterResponse: { res async throws in
                #expect(res.status == .ok)
                #expect(try
                    res.content.decode([UserDTO].self).sorted(by: { ($0.username ?? "") < ($1.username ?? "") }) ==
                    sampleUsers.map { $0.toDTO() }.sorted(by: { ($0.username ?? "") < ($1.username ?? "") })
                )
            })
        }
    }
    
    @Test("Creating a User")
    func createUser() async throws {
        let newUser = User(id: nil, username: "test", password: "password")
        
        try await withApp { app in
            try await app.testing().test(.POST, "users", beforeRequest: { req in
                try req.content.encode(newUser)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let models = try await User.query(on: app.db).all()
                #expect(models.map({ $0.toDTO().username }) == [newUser.username])
            })
        }
    }
}

extension UserDTO: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.username == rhs.username
    }
}
