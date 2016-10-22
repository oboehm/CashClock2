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
    var session = WCSession.default()
    
    // Instantiate the Singleton
    static let sharedManager = ConnectivityHandler()
    
    var messages = String() {
        // fire KVO-updates for Swift property
        willSet { willChangeValue(forKey: "messages") }
        didSet  { didChangeValue(forKey: "messages")  }
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
        session.activate()
        print("ConnectivityHandler.\(#function): \(session) activated.")
        print("ConnectivityHandler.\(#function): Paired: \(session.isPaired) / Installed: \(session.isWatchAppInstalled) / Reachable: \(session.isReachable)")
    }
    
    // MARK: - WCSessionDelegate
    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                        error: Error?) {
        print("ConnectivityHandler.\(#function): session '\(session)' received with \(activationState) and \(error).")
    }

    /** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("ConnectivityHandler.\(#function): session '\(session)' become inactive.")
    }
    
    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    @available(iOS 9.3, *)
    public func sessionDidDeactivate(_ session: WCSession) {
        print("ConnectivityHandler.\(#function): session '\(session)' did deactivate.")
    }
    
    /**
     * This method will be triggered if the watch part transfers a ClockCalculator
     * object as userInfo.
     */
    @available(iOS 9.0, *)
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("ConnectivityHandler.\(#function): message '\(message)' received.")
        let data = message["data"]
        if (data is String) {
            let str = data as! String
            transfered.setData(data: str)
        }
        self.messages = "data \(data)"
    }
    
    /**
     * This method will be triggered if the watch part transfers a ClockCalculator
     * object as userInfo.
     */
    @available(iOS 9.0, *)
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print("ConnectivityHandler.\(#function): userInfo '\(userInfo)' received.")
        let data = userInfo["data"]
        if (data is String) {
            let str = data as! String
            transfered.setData(data: str)
        }
        self.messages = "data \(data)"
    }
    
    /**
     * Versuche mit session.transferUserInfo und session.updateApplicationContext
     * haben leider nicht funktioniert. Daher greifen wir jetzt auf die
     * Variante mit session.sendMessage zurueck.
     * Dummerweise kann man mit session.sendMessage nur einfache Datentypen
     * wie String verschicken.
     */
    func transferDataOf(calculator: ClockCalculator) {
        print("ConnectivityHander.\(#function): sending data of \(calculator) to watch...")
        self.session.sendMessage(["data" : calculator.description], replyHandler: nil) { (error) in
            print("Error sending message: \(error)")
        }
        print("ConnectivityHander.\(#function): \(calculator) sended via \(self.session) with complicationEnabled=\(self.session.isComplicationEnabled).")
    }
    
}



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var connectivityHandler : ConnectivityHandler?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("AppDelegate.\(#function): \(application) launched.")
        if (WCSession.isSupported()) {
            self.connectivityHandler = ConnectivityHandler()
            print("AppDelegate.\(#function): WCSession supported.")
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("AppDelegate.\(#function): \(application) is inactive.")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("AppDelegate.\(#function): \(application) entered background.")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("AppDelegate.\(#function): \(application) entered foreground.")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("AppDelegate.\(#function): \(application) is active.")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("AppDelegate.\(#function): \(application) terminated.")
    }


}

