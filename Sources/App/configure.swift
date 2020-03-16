import Fluent
import FluentSQLiteDriver
import Vapor
import SendGridKit

// configures your application
public func configure(_ app: Application) throws {
    
    guard let jwks = Environment.get("JWKS") else {
        fatalError("Unable to retrieve JWKS from Environment")
    }
    
    try app.jwt.signers.use(jwksJSON: jwks)

    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    app.migrations.add(CreateUser())

    guard let sendGridAPIKey = Environment.get("SENDGRID_API_KEY") else {
       fatalError("Unable to retrieve SendGrid API Key from Environment")
    }
    
    let sendGridClient = SendGridClient(httpClient: app.client.http, apiKey: sendGridAPIKey)

    try routes(app, sendGridClient: sendGridClient)
}
