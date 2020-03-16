import Vapor
import JWT

struct ConfirmationPayload: JWTPayload {
    static let defaultExpiration: TimeInterval = 3600
    
    let userId: UUID
    let exp: TimeInterval
    
    init(userId: UUID, expiration: TimeInterval = defaultExpiration) {
        self.userId = userId
        self.exp = Date().addingTimeInterval(expiration).timeIntervalSince1970
    }
    
    func verify(using signer: JWTSigner) throws {
        try ExpirationClaim(value:Date(timeIntervalSinceNow: exp)).verifyNotExpired()
    }
}


