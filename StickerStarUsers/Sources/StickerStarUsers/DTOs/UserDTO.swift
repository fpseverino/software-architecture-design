import Fluent
import Vapor

/// A DTO representing a user, including its ID and username.
///
/// The DTO is used to avoid exposing internal database models directly to the API consumers,
/// providing a layer of abstraction and security.
struct UserDTO: Content {
    var id: UUID?
    var username: String?
    
    /// Converts the DTO back to a ``User`` model, which can be used for database operations.
    /// > Note: The password is not included in the DTO for security reasons,
    ///     so it must be set separately when creating or updating a user in the database.
    /// - Returns: A ``User`` model representing the user, with the ID and username set from the DTO.
    func toModel() -> User {
        let model = User()
        
        model.id = self.id
        if let username = self.username {
            model.username = username
        }
        return model
    }
}
