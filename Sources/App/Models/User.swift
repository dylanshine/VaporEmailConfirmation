import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String

    @Field(key: "confirmed")
    var confirmed: Bool
    
    init() { }

    init(email: String,
         password: String) throws {
        self.email = email
        self.password = try BCryptDigest().hash(password)
        self.confirmed = false
    }
}
