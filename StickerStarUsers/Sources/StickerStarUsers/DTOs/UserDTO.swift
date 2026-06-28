import Fluent
import Vapor

struct UserDTO: Content {
    var id: UUID?
    var username: String?
    
    func toModel() -> User {
        let model = User()
        
        model.id = self.id
        if let username = self.username {
            model.username = username
        }
        return model
    }
}
