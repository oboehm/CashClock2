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

/**
 * This class is singleton to wrap a WCSession. Some of the code here is
 * insprired by https://gist.github.com/NatashaTheRobot/6bcbe79afd7e9572edf6.
 */
class ConnectivityHandler : NSObject, WCSessionDelegate {
    
    // Keep a reference for the session,
    // which will be used later for sending / receiving data
    var session = WCSession.defaultSession()

//    // Add a validSession variable to check that the Watch is paired
//    // and the Watch App installed to prevent extra computation
//    // if these conditions are not met.
//    // This is a computed property, since the user can pair their device and / or
//    // install your app while using your iOS app, so this can become valid
//    private var validSession: WCSession? {
//        // paired - the user has to have their device paired to the watch
//        // watchAppInstalled - the user must have your watch app installed
//        // Note: if the device is paired, but your watch app is not installed
//        // consider prompting the user to install it for a better experience
//        if let session = session where session.paired && session.watchAppInstalled {
//            return session
//        }
//        return nil
//    }
    
    // Instantiate the Singleton
    static let sharedManager = ConnectivityHandler()
    
    var messages = String() {
        // fire KVO-updates for Swift property
        willSet { willChangeValueForKey("messages") }
        didSet  { didChangeValueForKey("messages")  }
    }
    var transfered = ClockCalculator()
    
    override init() {
        super.init()
        self.startSession()
    }
    
    /**
     * Activate Session
     * This needs to be called to activate the session before first use!
     */
    func startSession() {
        session.delegate = self
        session.activateSession()
        print("ConnectivityHandler.\(__FUNCTION__): \(session) activated.")
        print("ConnectivityHandler.\(__FUNCTION__): Paired: \(session.paired) / Installed: \(session.watchAppInstalled) / Reachable: \(session.reachable)")
    }

    // MARK: - WCSessionDelegate
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        print("ConnectivityHandler.\(__FUNCTION__): message '\(message)' received with replyHander \(replyHandler).")
    }
    
    /**
     * This method will be triggered if the watch part transfers a ClockCalculator
     * object as userInfo.
     */
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        print("ConnectivityHandler.\(__FUNCTION__): message '\(message)' received.")
        let state = message["state"]
        if (state is String) {
            let str = state as! String
            transfered.state = State(rawValue: str)!
        }
        self.messages = "state \(state)"
    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        print("ConnectivityHandler.\(__FUNCTION__): \(applicationContext) received.")
    }
    
    /**
     * This method will be triggered if the watch part transfers a ClockCalculator
     * object as userInfo.
     */
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        print("ConnectivityHandler.\(__FUNCTION__): userInfo '\(userInfo)' received.")
        let state = userInfo["state"]
        if (state is String) {
            let str = state as! String
            transfered.state = State(rawValue: str)!
        }
        self.messages = "state \(state)"
    }
    
    /**
     *  FIXME: session.updateApplicationContext oder session.sendMessage benutzen
     *         (fuer sofortige Uebertragunt)!
     */
    func transferStateOf(calculator: ClockCalculator) {
        print("ConnectivityHander.\(__FUNCTION__): sending \(calculator) to watch...")
        //self.session.transferUserInfo(["state" : calculator.state.rawValue])
        self.session.sendMessage(["state" : calculator.state.rawValue], replyHandler: nil) { (error) in
            NSLog("Error sending message: %@", error)
        }
        print("ConnectivityHander.\(__FUNCTION__): \(calculator.state) sended via \(self.session) with complicationEnabled=\(self.session.complicationEnabled).")
    }

}



// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
//extension ConnectivityHandler {
//    
//    /**
//     * Sender: This is where the magic happens!
//     * Just updateApplicationContext on the session!
//     */
//    func updateApplicationContext(applicationContext: [String : AnyObject]) throws {
//        if let session = validSession {
//            do {
//                try session.updateApplicationContext(applicationContext)
//            } catch let error {
//                throw error
//            }
//        }
//    }
//    
//}



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var connectivityHandler : ConnectivityHandler?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        print("AppDelegate.\(__FUNCTION__): \(application) launched.")
        if (WCSession.isSupported()) {
            self.connectivityHandler = ConnectivityHandler()
            print("AppDelegate.\(__FUNCTION__): WCSession supported.")
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

