//
//  InterfaceController.swift
//  CashWatch Extension
//
//  Created by oliver on 11.10.15.
//  Copyright © 2015 Oliver Boehm. All rights reserved.
//

import WatchKit
import Foundation


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
        print("InterfaceController.\(__FUNCTION__): button was tapped.")
        if (started) {
            watchTimer.stop()
            calculator.stopTimer()
            startButton.setTitle("Start")
        } else {
            watchTimer.setDate(NSDate(timeIntervalSinceNow: 0))
            watchTimer.start()
            calculator.startTimer()
            startButton.setTitle("Stop")
        }
        started = !started
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        updateElapsedMoney(calculator.getMoney())
        calculator.addObserver(self)
        print("InterfaceController.\(__FUNCTION__): \(context) was initialized.")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        print("InterfaceController.\(__FUNCTION__): controller is visible.")
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        print("InterfaceController.\(__FUNCTION__): controller is no longer visible.")
    }

   /**
    * This method will be called by the observed CashCalculator.
    */
    func update(time:NSTimeInterval, money:Double) {
        updateElapsedMoney(money)
    }

    /**
     * We do not only update the text for the money labal we also set the font
     * to monospaced and the correct locale / currency.
     */
    private func updateElapsedMoney(money:Double) {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        let systemFont = UIFont.monospacedDigitSystemFontOfSize(32, weight: UIFontWeightRegular)
        if let string = formatter.stringFromNumber(money) {
            let attributedString = NSAttributedString(string: string, attributes: [NSFontAttributeName: systemFont])
            self.moneyLabel.setAttributedText(attributedString)
        }
    }

}
