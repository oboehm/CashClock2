//
//  InterfaceController.swift
//  CashWatch Extension
//
//  Created by oliver on 11.10.15.
//  Copyright © 2015 Oliver Boehm. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, ClockObserver, WCSessionDelegate {

    @IBOutlet weak var moneyLabel: WKInterfaceLabel!
    @IBOutlet weak var watchTimer: WKInterfaceTimer!
    @IBOutlet weak var startButton: WKInterfaceButton!
    @IBOutlet weak var personHourLabel: WKInterfaceLabel!
    var calculator = ClockCalculator()
    var session = WCSession?()
    
   /**
    * This method is called if start / stop button will be pressed on the
    * watch.
    */
    // TODO set color (green / red)
    @IBAction func buttonTapped() {
        print("\(unsafeAddressOf(self))-InterfaceController.\(__FUNCTION__): button was tapped.")
        switch (calculator.state) {
        case .Init:
            self.startTimer()
            break;
       case .Started, .Continued:
            self.stopTimer()
            break;
        case .Stopped:
            self.continueTimer()
            break;
        }
        session?.transferUserInfo(["state" : calculator.state.rawValue])
        print("\(unsafeAddressOf(self))-InterfaceController.\(__FUNCTION__): \(calculator.state) sended via \(session).")
    }
    
    private func startTimer() {
        let time = calculator.getTime()
        watchTimer.setDate(NSDate(timeIntervalSinceNow: -time))
        watchTimer.start()
        calculator.startTimer()
        startButton.setTitle("stop")
    }
    
    private func stopTimer() {
        watchTimer.stop()
        calculator.stopTimer()
        startButton.setTitle("continue")
    }
    
    private func continueTimer() {
        let time = calculator.getTime()
        watchTimer.setDate(NSDate(timeIntervalSinceNow: -time))
        watchTimer.start()
        calculator.continueTimer()
        startButton.setTitle("stop")
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        updateElapsedMoney(calculator.getMoney())
        calculator.addObserver(self)
        setPersonHourLabel()
        startButton.setTitle("start")
        print("\(unsafeAddressOf(self))-InterfaceController.\(__FUNCTION__): \(context) was initialized.")
    }
    
    private func setPersonHourLabel() {
        let formatted = String(calculator.numberOfPersons) + " x "
            + getMoneyFormatted(calculator.costPerHour, fractionDigits:0)
        self.personHourLabel.setText(formatted)
        print("\(unsafeAddressOf(self))-InterfaceController.\(__FUNCTION__): label is set to '\(formatted)'.")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
            session?.delegate = self
            session?.activateSession()
            print("\(unsafeAddressOf(self))-InterfaceController.\(__FUNCTION__): session \(session) is activated.")
            print("\(unsafeAddressOf(self))-InterfaceController.\(__FUNCTION__): Reachable: \(session?.reachable)  / Delegate: \(session?.delegate)")
        }
        print("\(unsafeAddressOf(self))-InterfaceController.\(__FUNCTION__): controller is visible.")
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        print("\(unsafeAddressOf(self))-InterfaceController.\(__FUNCTION__): controller is no longer visible.")
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
        let systemFont = UIFont.monospacedDigitSystemFontOfSize(32, weight: UIFontWeightRegular)
        let moneyString = getMoneyFormatted(money, fractionDigits:2)
        let attributedString = NSAttributedString(string: moneyString,
            attributes: [NSFontAttributeName: systemFont])
        self.moneyLabel.setAttributedText(attributedString)
    }
    
    private func getMoneyFormatted(money:NSNumber, fractionDigits:Int) -> String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.maximumFractionDigits = fractionDigits
        let moneyFormatted = formatter.stringFromNumber(money)
        return moneyFormatted!
    }

    // MARK: - WCSessionDelegate
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        //print("InterfaceController.\(__FUNCTION__): received message = \(message).")
        let state = message["state"]
        if (state is String) {
            let str = state as! String
            let state = State(rawValue: str)!
            print("\(unsafeAddressOf(self))-InterfaceController.\(__FUNCTION__): state \(state) received.")
            switch (state) {
            case .Started:              // "Start" was received
                self.startTimer();
                break
            case .Continued:            // "Cont'd" was received
                self.continueTimer();
                break;
            case .Stopped:              // "Stop" was received
                self.stopTimer()
                break
            case .Init:
                calculator.resetTimer()
                break
            }
        }
        //        var remoteCalc: ClockCalculator?
        //        let calc = userInfo["calc"]
        //        remoteCalc = calc as? ClockCalculator
        //        if (remoteCalc != nil) {
        //            syncCalculator(remoteCalc!)
        //        }
        //        print("InterfaceController.\(__FUNCTION__): received calc = \(calc).")
        //        print("InterfaceController.\(__FUNCTION__): received calc = \(remoteCalc).")
    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext:
            [String : AnyObject]) {
        print("\(unsafeAddressOf(self))-InterfaceController.\(__FUNCTION__): received applicationContext = \(applicationContext) is ignored.")
        //let msg = applicationContext["msg"]!
        //print("InterfaceController.\(__FUNCTION__): msg = \(msg).")
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        print("\(unsafeAddressOf(self))-InterfaceController.\(__FUNCTION__): received userInfo = \(userInfo) is ignored.")
    }
    
    private func syncCalculator(remoteCalc: ClockCalculator) {
        self.calculator.numberOfPersons = remoteCalc.numberOfPersons
        self.calculator.costPerHour = remoteCalc.costPerHour
        print("\(unsafeAddressOf(self))-InterfaceController.\(__FUNCTION__): calculator is synced with \(remoteCalc).")
        self.setPersonHourLabel()
    }

}
