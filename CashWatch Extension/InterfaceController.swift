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
    @IBOutlet var personPicker: WKInterfacePicker!
    var calculator = ClockCalculator()
    var session = WCSession?()
    
   /**
     @IBOutlet var pi: WKInterfaceImage!
    * This method is called if start / stop button will be pressed on the
    * watch.
    */
    // TODO set color (green / red)
    @IBAction func buttonTapped() {
        print("\(unsafeAddressOf(self))-InterfaceController.\(#function): button was tapped.")
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
        //session?.transferUserInfo(["state" : calculator.state.rawValue])
        session?.transferUserInfo(["data" : calculator.description])
        print("\(unsafeAddressOf(self))-InterfaceController.\(#function): \(calculator.description) sended via \(session).")
    }
    
    private func resetTimer() {
        self.calculator.resetTimer()
        let time = calculator.getTime()
        watchTimer.setDate(NSDate(timeIntervalSinceNow: -time))
        startButton.setTitle(NSLocalizedString("start", comment:"start"))
    }

    private func startTimer() {
        let time = calculator.getTime()
        watchTimer.setDate(NSDate(timeIntervalSinceNow: -time))
        watchTimer.start()
        calculator.startTimer()
        startButton.setTitle(NSLocalizedString("stop", comment:"stop"))
    }
    
    private func stopTimer() {
        watchTimer.stop()
        calculator.stopTimer()
        startButton.setTitle(NSLocalizedString("continue", comment:"continue"))
    }
    
    private func continueTimer() {
        let time = calculator.getTime()
        watchTimer.setDate(NSDate(timeIntervalSinceNow: -time))
        watchTimer.start()
        calculator.continueTimer()
        startButton.setTitle(NSLocalizedString("stop", comment:"stop"))
    }
    
    @IBAction func pickerSelectedItemChanged(value: Int) {
        print("\(unsafeAddressOf(self))-InterfaceController.\(#function): item \(value) selected.")
        self.calculator.numberOfPersons = value + 1;
        self.setPersonHourLabel()
        session?.transferUserInfo(["data" : calculator.description])
        print("\(unsafeAddressOf(self))-InterfaceController.\(#function): \(calculator.description) sended via \(session).")
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        updateElapsedMoney(calculator.getMoney())
        calculator.addObserver(self)
        startButton.setTitle("start")
        
        // setup picker
//        var pickerItems: [WKPickerItem] = []
//        for i in 1...5 {
//            let item = WKPickerItem()
//            item.contentImage = WKImage(imageName: "man\(i).png")
//            pickerItems.append(item)
//        }
//        self.personPicker.setItems(pickerItems)
        let pickerItems: [WKPickerItem] = (1...100).map {
            let pickerItem = WKPickerItem()
            let i = $0
            if (i < 5) {
                pickerItem.contentImage = WKImage(imageName: "man\(i).png")
            } else {
                pickerItem.contentImage = WKImage(imageName: "man5.png")
            }
            return pickerItem
        }
        self.personPicker.setItems(pickerItems)
        self.updateOutlets()
        
        print("\(unsafeAddressOf(self))-InterfaceController.\(#function): \(context) was initialized.")
    }
    
    private func setPersonHourLabel() {
        let formatted = String(calculator.numberOfPersons) + " x "
            + getMoneyFormatted(calculator.costPerHour, fractionDigits:0)
        self.personHourLabel.setText(formatted)
        print("\(unsafeAddressOf(self))-InterfaceController.\(#function): label is set to '\(formatted)'.")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
            session?.delegate = self
            session?.activateSession()
            print("\(unsafeAddressOf(self))-InterfaceController.\(#function): session \(session) is activated.")
            print("\(unsafeAddressOf(self))-InterfaceController.\(#function): Reachable: \(session?.reachable)  / Delegate: \(session?.delegate)")
        }
        print("\(unsafeAddressOf(self))-InterfaceController.\(#function): controller is visible.")
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        print("\(unsafeAddressOf(self))-InterfaceController.\(#function): controller is no longer visible.")
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
        print("\(unsafeAddressOf(self))-InterfaceController.\(#function): received message = \(message).")
//        let state = message["state"]
//        if (state is String) {
//            let str = state as! String
//            let state = State(rawValue: str)!
//            switch (state) {
//            case .Init:                 // "Reset" was received
//                self.resetTimer()
//                break
//            case .Started:              // "Start" was received
//                self.startTimer();
//                break
//            case .Continued:            // "Cont'd" was received
//                self.continueTimer();
//                break;
//            case .Stopped:              // "Stop" was received
//                self.stopTimer()
//                break
//            }
//        }
        let data = message["data"]
        if (data is String) {
            let oldState = self.calculator.state
            let dat = data as! String
            self.updateData(dat)
            if (oldState != self.calculator.state) {
                print("\(unsafeAddressOf(self))-InterfaceController.\(#function): state of \(calculator) has changed from \(oldState).")
                switch (self.calculator.state) {
                case .Init:                 // "Reset" was received
                    self.resetTimer()
                    break
                case .Started:              // "Start" was received
                    self.startTimer();
                    break
                case .Continued:            // "Cont'd" was received
                    self.continueTimer();
                    break;
                case .Stopped:              // "Stop" was received
                    self.stopTimer()
                    break
                }
            }
        }
    }
    
    /**
     *  Because the data from the remote site may be transfered some time
     *  later we update the elapsed money only if the received data has a
     *  a bigger amount.
     */
    func updateData(data: String) {
        print("\(unsafeAddressOf(self))-InterfaceController.\(#function): \(calculator) will be updated with \(data).")
        let calc = ClockCalculator()
        calc.setData(data)
        self.calculator.costPerHour = calc.costPerHour
        self.calculator.numberOfPersons = calc.numberOfPersons
        switch (calc.state) {
        case .Started, .Continued:
            if (calc.getMoney() > self.calculator.getMoney()) {
                self.calculator.setData(data);
                print("\(unsafeAddressOf(self))-InterfaceController.\(#function): \(calculator) completely updated.")
            } else {
                self.calculator.state = calc.state
                print("\(unsafeAddressOf(self))-InterfaceController.\(#function): \(calculator) partially updated.")
            }
        default:
            print("\(unsafeAddressOf(self))-InterfaceController.\(#function): \(calculator) completely updated.")
            self.calculator.setData(data);
        }
        self.updateOutlets()
    }
    
    func updateOutlets() {
        self.setPersonHourLabel()
        self.personPicker.setSelectedItemIndex(calculator.numberOfPersons - 1)
        self.updateElapsedMoney(self.calculator.getMoney())

    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext:
            [String : AnyObject]) {
        print("\(unsafeAddressOf(self))-InterfaceController.\(#function): received applicationContext = \(applicationContext) is ignored.")
        //let msg = applicationContext["msg"]!
        //print("InterfaceController.\(__FUNCTION__): msg = \(msg).")
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        print("\(unsafeAddressOf(self))-InterfaceController.\(#function): received userInfo = \(userInfo) is ignored.")
    }
    
    private func syncCalculator(remoteCalc: ClockCalculator) {
        self.calculator.numberOfPersons = remoteCalc.numberOfPersons
        self.calculator.costPerHour = remoteCalc.costPerHour
        print("\(unsafeAddressOf(self))-InterfaceController.\(#function): calculator is synced with \(remoteCalc).")
        self.setPersonHourLabel()
    }

}
