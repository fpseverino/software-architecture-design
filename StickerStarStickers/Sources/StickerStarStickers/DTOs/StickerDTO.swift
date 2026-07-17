import Fluent
import Vapor

/// A DTO representing a sticker, including its ID, name, and the ID of the user who owns it.
///
/// The DTO is used to avoid exposing internal database models directly to the API consumers, providing a layer of abstraction and security.
struct StickerDTO: Content {
    var id: UUID?
    var name: String?
    var userID: UUID?
    
    /// Converts the DTO back to a ``Sticker`` model, which can be used for database operations.
    func toModel() -> Sticker {
        let model = Sticker()
        
        model.id = self.id
        if let name = self.name {
            model.name = name
        }
        if let userID = self.userID {
            model.userID = userID
        }
        return model
    }
}
