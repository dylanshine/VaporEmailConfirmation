import Vapor

struct UserInput: Content {
    let email: String
    let password: String
}
