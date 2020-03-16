import Fluent
import Vapor
import SendGridKit

struct AuthController {
    
    private let sendGridClient: SendGridClient
    
    init(sendGridClient: SendGridClient) {
        self.sendGridClient = sendGridClient
    }
    
    func register(_ request: Request) throws -> EventLoopFuture<HTTPStatus> {
        let input = try request.content.decode(UserInput.self)
        
        let user = try User(email: input.email,
                            password: input.password)
        
        return User.query(on: request.db)
            .filter(\.$email == user.email)
            .count()
            .flatMap {
                guard $0 == 0 else {
                    return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "This email is already registered"))
                }
               
                return user.save(on: request.db)
                    .transform(to: user)
                    .flatMap { user  in
                        guard let userId = user.id else {
                            return request.eventLoop.makeFailedFuture(Abort(.internalServerError))
                        }
                        
                        let payload = ConfirmationPayload(userId: userId)
                        
                        do {
                            let token = try request.application.jwt.signers.sign(payload)
                            return try self.sendVerificationEmail(email: user.email, token: token, request)
                                .transform(to: .ok)
                        } catch {
                            return request.eventLoop.makeFailedFuture(Abort(.internalServerError))
                        }
                }
        }
    }
    
    func sendVerificationEmail(email: String, token: String, _ request: Request) throws -> EventLoopFuture<Void> {
        
        let subject: String = "Confirm Your Registration"
        let body: String = "Click on this link to confirm your email http://127.0.0.1:8080/confirm?token=\(token)"
        
        let from = EmailAddress(email: "developer@shinelabs.com")
        
        let address = EmailAddress(email: email)
        
        let header = Personalization(to: [address], subject: subject)
        
        let email = SendGridEmail(personalizations: [header],
                                  from: from,
                                  subject: subject,
                                  content: [["type": "text", "value": body]])
        
        return try sendGridClient.send(email: email, on: request.eventLoop)
    }
    
    func confirm(_ request: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let token = try? request.query.get(String.self, at: "token") else {
            throw Abort(.badRequest)
        }
        
        let payload: ConfirmationPayload = try request.application.jwt.signers.verify(token, as: ConfirmationPayload.self)

        return User.find(payload.userId, on: request.db)
            .flatMap { user in
                guard let user = user else {
                    return request.eventLoop.makeFailedFuture(Abort(.notFound,  reason: "User no longer exists."))
                }
                
                guard !user.confirmed else {
                    return request.eventLoop.makeFailedFuture(Abort(.badRequest,  reason: "User's email is already confirmed."))
                }
                
                user.confirmed = true
                return user.save(on: request.db)
                    .transform(to: .ok)
        }
    }
}

