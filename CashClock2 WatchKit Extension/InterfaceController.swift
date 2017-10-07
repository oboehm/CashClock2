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


class InterfaceController: WKInterfaceController, ClockObserver, WCSessionDelegate {

    @IBOutlet weak var moneyLabel: WKInterfaceLabel!
    @IBOutlet weak var watchTimer: WKInterfaceTimer!
    @IBOutlet weak var startButton: WKInterfaceButton!
    @IBOutlet weak var personHourLabel: WKInterfaceLabel!
    @IBOutlet var personPicker: WKInterfacePicker!
    var calculator = ClockCalculator()
    var session = WCSession.default

    @IBAction func menuItemPressed() {
        print("\(Unmanaged.passUnretained(self).toOpaque())-InterfaceController.\(#function): menu item was pressed.")
        self.resetTimer()
        self.sendData()
    }
    
    /**
     * This method is called if start / stop button will be pressed on the
     * watch.
     */
    // TODO set color (green / red)
    @IBAction func buttonTapped() {
        print("\(Unmanaged.passUnretained(self).toOpaque())-InterfaceController.\(#function): button was tapped.")
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
        self.sendData()
    }

    private func sendData() {
        session.transferUserInfo(["data" : calculator.description])
        print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): \(calculator.description) sended via \(session).")
        
    }
    
    private func resetTimer() {
        self.calculator.resetTimer()
        let time = calculator.getTime()
        watchTimer.setDate(NSDate(timeIntervalSinceNow: -time) as Date)
        self.updateElapsedMoney(money: 0)
        startButton.setTitle(NSLocalizedString("start", comment:"start"))
    }
    
    private func startTimer() {
        let time = calculator.getTime()
        watchTimer.setDate(NSDate(timeIntervalSinceNow: -time) as Date)
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
        watchTimer.setDate(NSDate(timeIntervalSinceNow: -time) as Date)
        watchTimer.start()
        calculator.continueTimer()
        startButton.setTitle(NSLocalizedString("stop", comment:"stop"))
    }
    
    @IBAction func pickerSelectedItemChanged(value: Int) {
        print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): item \(value) selected.")
        self.calculator.numberOfPersons = value + 1;
        self.setPersonHourLabel()
        session.transferUserInfo(["data" : calculator.description])
        print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): \(calculator.description) sended via \(session).")
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        updateElapsedMoney(money: calculator.getMoney())
        let n = calculator.addObserver(self)
        print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): self added as observer \(n) to \(calculator).")
        startButton.setTitle("start")
        
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
        
        print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): \(context) was initialized.")
    }

    private func setPersonHourLabel() {
        let formatted = String(calculator.numberOfPersons) + " x "
            + getMoneyFormatted(money: NSNumber(value:calculator.costPerHour), fractionDigits:0)
        self.personHourLabel.setText(formatted)
        print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): label is set to '\(formatted)'.")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        session.delegate = self
        session.activate()
        print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): controller is visible, \(session) activated.")
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): controller is no longer visible.")
    }

    /**
     * This method will be called by the observed CashCalculator.
     */
    func update(_ time:TimeInterval, money:Double) {
        updateElapsedMoney(money: money)
    }

    /**
     * We do not only update the text for the money labal we also set the font
     * to monospaced and the correct locale / currency.
     */
    private func updateElapsedMoney(money:Double) {
        let systemFont = UIFont.monospacedDigitSystemFont(ofSize: 32, weight: UIFont.Weight.regular)
        let moneyString = getMoneyFormatted(money: NSNumber(value: money), fractionDigits:2)
        let attributedString = NSAttributedString(string: moneyString,
                                                  attributes: [NSAttributedStringKey.font: systemFont])
        self.moneyLabel.setAttributedText(attributedString)
    }
    
    private func getMoneyFormatted(money:NSNumber, fractionDigits:Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = fractionDigits
        let moneyFormatted = formatter.string(from: money)
        return moneyFormatted!
    }
    
    // MARK: - WCSessionDelegate
    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                        error: Error?) {
        print("InterfaceController.\(#function): session '\(session)' received with \(activationState) and \(error).")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): received message = \(message).")
        let data = message["data"]
        if (data is String) {
            let oldState = self.calculator.state
            let dat = data as! String
            self.updateData(data: dat)
            if (oldState != self.calculator.state) {
                print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): state of \(calculator) has changed from \(oldState).")
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
        print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): \(calculator) will be updated with \(data).")
        let calc = ClockCalculator()
        calc.setData(data: data)
        self.calculator.costPerHour = calc.costPerHour
        self.calculator.numberOfPersons = calc.numberOfPersons
        switch (calc.state) {
        case .Started, .Continued:
            if (calc.getMoney() > self.calculator.getMoney()) {
                self.calculator.setData(data: data);
                print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): \(calculator) completely updated.")
            } else {
                self.calculator.state = calc.state
                print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): \(calculator) partially updated.")
            }
        default:
            print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): \(calculator) completely updated.")
            self.calculator.setData(data: data);
        }
        self.updateOutlets()
    }
    
    func updateOutlets() {
        self.setPersonHourLabel()
        self.personPicker.setSelectedItemIndex(calculator.numberOfPersons - 1)
        self.updateElapsedMoney(money: self.calculator.getMoney())
        
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext:
        [String : Any]) {
        print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): received applicationContext = \(applicationContext) is ignored.")
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): received userInfo = \(userInfo) is ignored.")
    }
    
    private func syncCalculator(remoteCalc: ClockCalculator) {
        self.calculator.numberOfPersons = remoteCalc.numberOfPersons
        self.calculator.costPerHour = remoteCalc.costPerHour
        print("\(Unmanaged.passUnretained(self))-InterfaceController.\(#function): calculator is synced with \(remoteCalc).")
        self.setPersonHourLabel()
    }

}
