//
//  InterfaceController.swift
//  CashClock2 WatchKit Extension
//
//  Created by oliver on 05.05.15.
//  Copyright (c) 2015 Oliver Böhm. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var moneyLabel: WKInterfaceLabel!
    @IBOutlet weak var watchTimer: WKInterfaceTimer!

    /**
     * This method is called if start / stop button will be pressed on the
     * watch.
     */
    @IBAction func buttonTapped() {
        println("InterfaceController.\(__FUNCTION__): button was tapped.")
        watchTimer.setDate(NSDate(timeIntervalSinceNow: 0))
        watchTimer.start()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        println("InterfaceController.\(__FUNCTION__): \(context) was initialized.")
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        println("InterfaceController.\(__FUNCTION__): controller is visible.")
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        println("InterfaceController.\(__FUNCTION__): controller is no longer visible.")
    }

}
