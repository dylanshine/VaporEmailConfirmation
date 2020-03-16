import Fluent
import Vapor
import SendGridKit

func routes(_ app: Application, sendGridClient: SendGridClient) throws {
    app.get { req -> String in
        return "It works!"
    }
    
    let controller = AuthController(sendGridClient: sendGridClient)
    app.post("register", use: controller.register)
    app.get("confirm", use: controller.confirm)
}
