import UIKit
import Foundation

// Declare a global variable for host name
var hostName: String?

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var appOpeningTime: TimeInterval?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        appOpeningTime = Date().timeIntervalSince1970
        
        // Asynchronously fetch the hostname
        DispatchQueue.global(qos: .background).async {
            self.getHostName {
                self.initializeApp()
            }
        }
        
        return true
    }
    
    // Fetch hostName asynchronously
    func getHostName(completion: @escaping () -> Void) {
        hostName = ProcessInfo.processInfo.hostName
        // Simulate delay if necessary
        DispatchQueue.main.async {
            completion()
        }
    }
    
    // Initialize the app after the hostname is retrieved
    func initializeApp() {
        guard let hostName = hostName else { return }
        
        // Perform initialization steps only after the hostname is available
        print("Host Name: \(hostName)")
        Icarus.instance()
        LoggingSystem.push(eventLog: ["event": "App is being opened", "hostName": hostName], verbose: false)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Release resources specific to discarded scenes.
    }
}
