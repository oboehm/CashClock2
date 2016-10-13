//
//  InterfaceController.swift
//  CashClock2 WatchKit Extension
//
//  Created by oliver on 05.05.15.
//  Copyright (c) 2015 Oliver Böhm. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, ClockObserver {

    @IBOutlet weak var moneyLabel: WKInterfaceLabel!
    @IBOutlet weak var watchTimer: WKInterfaceTimer!
    @IBOutlet weak var startButton: WKInterfaceButton!
    var calculator = ClockCalculator()
    var started = false

    /**
     * This method is called if start / stop button will be pressed on the
     * watch.
     */
    @IBAction func buttonTapped() {
        print("InterfaceController.\(#function): button was tapped.")
        if (started) {
            watchTimer.stop()
            startButton.setTitle("Start")
        } else {
            watchTimer.setDate(NSDate(timeIntervalSinceNow: 0) as Date)
            watchTimer.start()
            startButton.setTitle("Stop")
        }
        started = !started
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        print("InterfaceController.\(#function): \(context) was initialized.")
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        print("InterfaceController.\(#function): controller is visible.")
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        print("InterfaceController.\(#function): controller is no longer visible.")
    }

    /**
     * This method will be called by the observed CashCalculator.
     */
    func update(_ time:TimeInterval, money:Double) {
        //updateElapsedMoney(money)
    }

}
