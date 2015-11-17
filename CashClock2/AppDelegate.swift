//
//  Copyright (c) 2015 Oliver Boehm. All rights reserved.
//
//  This file is part of CashClock2.
//
//  CashClock2 is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  CashClock2 is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with CashClock2. If not, see <http://www.gnu.org/licenses/>.
//
//  (c)reated by oliver on 19.03.15 (ob@cashclock.de)
//

import UIKit
import WatchConnectivity

class ConnectivityHandler : NSObject, WCSessionDelegate {
    
    var session = WCSession.defaultSession()
    
    var messages = [String]() {
        // fire KVO-updates for Swift property
        willSet { willChangeValueForKey("messages") }
        didSet  { didChangeValueForKey("messages")  }
    }
    
    override init() {
        super.init()
        session.delegate = self
        session.activateSession()
        print("ConnectivityHandler.\(__FUNCTION__): \(session) activated.")
        print("ConnectivityHandler.\(__FUNCTION__): Paired: \(session.paired) / Installed: \(session.watchAppInstalled) / Reachable: \(session.reachable)")
    }
    
    // MARK: - WCSessionDelegate
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        print("ConnectivityHandler.\(__FUNCTION__): message '\(message)' received with replyHander \(replyHandler).")
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        print("ConnectivityHandler.\(__FUNCTION__): message '\(message)' received.")
        //let msg = message["msg"]!
        //self.messages.append("Message \(msg)")
    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        print("ConnectivityHandler.\(__FUNCTION__): \(applicationContext) received.")
        //let msg = applicationContext["msg"]!
        //self.messages.append("AppContext \(msg)")
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        print("ConnectivityHandler.\(__FUNCTION__): userInfo '\(userInfo)' received.")
        //let msg = userInfo["msg"]!
        //self.messages.append("UserInfo \(msg)")
    }
    
}



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var connectivityHandler : ConnectivityHandler?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        print("AppDelegate.\(__FUNCTION__): \(application) launched.")
        if WCSession.isSupported() {
            self.connectivityHandler = ConnectivityHandler()
            print("AppDelegate.\(__FUNCTION__): WCSession supported.")
        } else {
            print("AppDelegate.\(__FUNCTION__): WCSession not supported (e.g. on iPad).")
        }
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("AppDelegate.\(__FUNCTION__): \(application) is inactive.")
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("AppDelegate.\(__FUNCTION__): \(application) entered background.")
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("AppDelegate.\(__FUNCTION__): \(application) entered foreground.")
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("AppDelegate.\(__FUNCTION__): \(application) is active.")
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("AppDelegate.\(__FUNCTION__): \(application) terminated.")
    }


}

