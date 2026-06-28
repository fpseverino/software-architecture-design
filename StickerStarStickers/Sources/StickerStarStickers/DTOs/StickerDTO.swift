import Fluent
import Vapor

struct StickerDTO: Content {
    var id: UUID?
    var name: String?
    var userID: UUID?
    
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
