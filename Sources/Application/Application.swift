import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudFoundryConfig
import SwiftMetrics
import SwiftMetricsDash
import CouchDB
import BluemixObjectStorage
import Credentials
import BluemixAppID

public let router = Router()
public let manager = ConfigurationManager()
public var port: Int = 8080

internal var couchDBClient: CouchDBClient?
internal var objectStorage: ObjectStorage?
internal var kituraCredentials: Credentials?
internal var webappKituraCredentialsPlugin: WebAppKituraCredentialsPlugin?

public func initialize() throws {

    manager.load(file: "config.json", relativeFrom: .project)
           .load(.environmentVariables)

    port = manager.port

    let sm = try SwiftMetrics()
    let _ = try SwiftMetricsDash(swiftMetricsInstance : sm, endpoint: router)

    let cloudantService = try manager.getCloudantService(name: "webSwiftBasic-cloudantNoSQLDB-5330")
    couchDBClient = CouchDBClient(service: cloudantService)

    let objectStorageService = try manager.getObjectStorageService(name: "webSwiftBasic-Object-Storage-5330")
    objectStorage = ObjectStorage(service: objectStorageService)
    try objectStorage?.connectSync(service: objectStorageService)

    let appIDService = try manager.getAppIDService(name: "webSwiftBasic-AdvancedMobileAccess-5330")
    webappKituraCredentialsPlugin = WebAppKituraCredentialsPlugin(service: appIDService,
                                                                  redirectUri: manager.url + "/api/appid/callback")
    kituraCredentials = Credentials()
    kituraCredentials?.register(plugin: webappKituraCredentialsPlugin!)

    router.all("/*", middleware: BodyParser())
    router.all("/", middleware: StaticFileServer())
}

public func run() throws {
    Kitura.addHTTPServer(onPort: port, with: router)
    Kitura.run()
}
