import Foundation
import UIKit

struct LoggingSystem {
    
    static func push(eventLog:[String:Any], verbose:Bool) {
        var log = eventLog
        
        log["deviceUserName"] = hostName
        log["deviceCloseToUser"] = UIDevice.current.proximityState

        Icarus.pushResource(log, withCallback: {data,response,error in guard let dict = data as? Dictionary<String,Any> else { return }
            if verbose {
                print("Posted log to: https://webdev.ewlab.di.unimi.it/icarus/str/\(dict["_id"] ?? "")")
            }
        })

    }

    
}

