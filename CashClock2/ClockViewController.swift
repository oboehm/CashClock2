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
//  (c)reated 26.03.15 by oliver (ob@cashclock.de)
//

import UIKit
import iAd
import WatchConnectivity

class ClockViewController: UIViewController, UITextViewDelegate, ClockObserver {
    
    @IBOutlet var textFieldMemberCount: UITextField!
    @IBOutlet var stepperMemberCount: UIStepper!
    @IBOutlet var textFieldCostPerHour: UITextField!
    @IBOutlet var startStopButton: UIButton!
    @IBOutlet var resetButton: UIButton!
    @IBOutlet var displayTimeLabel: UILabel!
    @IBOutlet var displayMoneyLabel: UILabel!
    @IBOutlet var costLabel: UILabel!
    var calculator = ClockCalculator()
    var connectivityHandler : ConnectivityHandler?

    /**
     * After the vew is loaded the used ClockCalculator is allocated and set up.
     * Also we set the property 'delegate' for internal text field
     * (see "Programmieren fuer iPhone und iPad", p. 279).
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        calculator.load()
        self.populateValues()
        updateNumberOfPersons(calculator.numberOfPersons)
        updateCostPerHour(calculator.costPerHour)
        let n = calculator.addObserver(self)
        print("ClockViewController.\(#function): \(self) is added as observer \(n).")
        self.registerForApplicationWillTerminate()
        self.connectivityHandler = (UIApplication.shared.delegate as? AppDelegate)?.connectivityHandler
        connectivityHandler?.addObserver(self, forKeyPath: "messages", options: NSKeyValueObservingOptions(), context: nil)
        self.transferDataToWatch()
        print("ClockViewController.\(#function): iPhone application loaded.")
    }
    
    /**
     * We want to be noticed if aplication will terminate.
     * from: http://stackoverflow.com/questions/2432536/applicationwillterminate-delegate-or-view
     */
    fileprivate func registerForApplicationWillTerminate() {
        let app = UIApplication.shared
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(UIApplicationDelegate.applicationWillTerminate(_:)),
            name: NSNotification.Name.UIApplicationWillTerminate,
            object: app)
    }
    
    func applicationWillTerminate(_ notification:Notification?) {
        calculator.save()
        print("ClockViewController.\(#function): \(notification) terminated.")
    }

    /**
     * This function populates values for some controls. The values which are
     * assigned for the fields will be displayed with localization format.
     * from: http://rshankar.com/internationalization-and-localization-of-apps-in-xcode-6-and-swift/
     */
    fileprivate func populateValues() {
        self.initCostLabel()
    }
    
    fileprivate func initCostLabel() {
        let numberFormatter = NumberFormatter()
        self.costLabel.text = numberFormatter.currencySymbol! + " "
            + NSLocalizedString("cost per hour", comment:"cost/h")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    /**
    * Here we set the number of persons. The code is written with the help of
    * http://www.ioslearner.com/uistepper-tutorial-example-sample-cod/
    */
    @IBAction func clickNumberOfPersonStepper(_ sender: UIStepper) {
        let value = sender.value
        calculator.numberOfPersons = Int(value)
        updateNumberOfPersons(Int(value))
        transferDataToWatch()
    }
    
    private func transferDataToWatch() {
        self.connectivityHandler?.transferDataOf(calculator: calculator)
        print("ClockViewController.\(#function): \(calculator) was transfered to watch.")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if let handler = self.connectivityHandler {
            if (object as AnyObject) === handler {
                print("ClockViewController.\(#function): \(object) with \(handler.transfered) received.")
                // see http://stackoverflow.com/questions/28302019/getting-a-this-application-is-modifying-the-autolayout-engine-error
                DispatchQueue.main.async(execute: {
                    if (handler.transfered.totalCost > self.calculator.totalCost) {
                        self.calculator.totalCost = handler.transfered.totalCost
                        print("ClockViewController.\(#function): total cost of \(self.calculator) updated.")
                    }
                    self.updateState(state: handler.transfered.state)
                    self.updateNumberOfPersons(handler.transfered.numberOfPersons)
                    self.updateCostPerHour(handler.transfered.costPerHour)
                })
            }
        }
    }

    private func updateState(state: State) {
        if (state != calculator.state) {
            print("ClockViewController.\(#function): State of \(calculator) will be set to \(state)")
            switch (state) {
            case .Started:              // "Start" was received
                calculator.startTimer()
                self.showStopButton()
                break
            case .Continued:            // "Cont'd" was received
                calculator.continueTimer();
                self.showStopButton()
                break;
            case .Stopped:              // "Stop" was received
                calculator.stopTimer()
                self.showContinueButton()
                break
            case .Init:
                calculator.resetTimer()
                self.resetStartButton()
                self.update(0, money: 0)
                break
            }
        }
    }
    
    fileprivate func updateNumberOfPersons(_ value: Int) {
        print("ClockViewController.\(#function): number of persons is set to \(value)")
        calculator.numberOfPersons = value
        stepperMemberCount.value = Double(calculator.numberOfPersons)
        textFieldMemberCount.text = String(calculator.numberOfPersons)
    }
    
    fileprivate func updateCostPerHour(_ value: Int) {
        print("ClockViewController.\(#function): cost per hour is set to \(value)")
        calculator.costPerHour = value
        textFieldCostPerHour.text = String(value)
    }

    /**
     * Her we start the timer. The code was first written with the help of
     * http://www.cocoa-coding.de/timer/timer.html and was then transfered
     * to Swift with the help of
     * http://rshankar.com/simple-stopwatch-app-in-swift/ .
     */
    @IBAction func clickStartStop(_ sender: AnyObject) {
        print("ClockViewController.\(#function): start/stop button pressed in state \(calculator.state)")
        switch (calculator.state) {
        case .Init:                 // "Start" was pressed
            calculator.startTimer()
            showStopButton()
            break
        case .Started, .Continued:  // "Stop" was pressed
            calculator.stopTimer()
            showContinueButton()
            break;
        case .Stopped:              // "continue" / "weiter" was pressed
            calculator.continueTimer()
            showStopButton()
            break
        }
        self.connectivityHandler?.transferDataOf(calculator: self.calculator)
        transferDataToWatch()
    }
    
    @IBAction func clickReset(_ sender: AnyObject) {
        resetTimer()
        resetStartButton()
        transferDataToWatch()
    }
    
    func resetTimer() {
        calculator.resetTimer()
        update(0.0, money: 0.0)
    }
    
    func resetStartButton() {
        startStopButton.setTitle(NSLocalizedString("start", comment:"start"),
            for: UIControlState())
    }
    
    func showStopButton() {
        startStopButton.setTitle(NSLocalizedString("stop", comment:"stop"),
            for: UIControlState())
        startStopButton.setTitleColor(UIColor.red, for: UIControlState())
        disable(resetButton)
    }
    
    func showContinueButton() {
        startStopButton.setTitle(NSLocalizedString("continue", comment:"cont"),
                                 for: UIControlState.normal)
        startStopButton.setTitleColor(UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0),
                                      for: UIControlState.normal)
        enable(resetButton)
    }
    
    func disable(_ button: UIButton) {
        button.isEnabled = false
        button.setTitleColor(UIColor.lightGray, for: UIControlState())
    }
    
    func enable(_ button: UIButton) {
        button.isEnabled = true
        button.setTitleColor(UIColor.black, for: UIControlState())
    }
    
    /**
     * This method will be called by the observed ClockCalculator.
     */
    func update(_ time:TimeInterval, money:Double) {
        updateElapsedTime(Int(time))
        updateElapsedMoney(money)
    }

    fileprivate func updateElapsedTime(_ time:Int) {
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = time / 3600
        self.displayTimeLabel.text = NSString(format: "%.2d:%.2d:%.2d", hours, minutes, seconds) as String
    }
    
    fileprivate func updateElapsedMoney(_ money:Double) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        self.displayMoneyLabel.text = formatter.string(from: NSNumber(value: money))
    }
    
    
    
    /////   Keyboard Handling   ////////////////////////////////////////////////////

    /**
     * To end editing and to let the keyboard disappear we override this
     * method from UITextViewDelegate.
     * see http://theapplady.net/workshop-9-hide-the-devices-keyboard/
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("ClockViewController.\(#function): User tapped in the background.");
        endEditingMemberCount()
        endEditingCostPerHour()
    }
    
    fileprivate func endEditingMemberCount() {
        var n = calculator.numberOfPersons
        textFieldMemberCount.endEditing(true)
        if !textFieldMemberCount.text!.isEmpty {
            n = Int(textFieldMemberCount.text!)!
        }
        print("ClockViewController.\(#function): Member count is set to \(n).");
        updateNumberOfPersons(n)
    }
    
    fileprivate func endEditingCostPerHour() {
        var n = calculator.costPerHour
        textFieldCostPerHour.endEditing(true)
        if !textFieldCostPerHour.text!.isEmpty {
            n = Int(textFieldCostPerHour.text!)!
        }
        print("ClockViewController.\(#function): Cost per hour is set to \(n).");
        updateCostPerHour(n)
        transferDataToWatch()
    }
    
    /**
     * If a text field is entered and the keyboard appears we have to move up the
     * view. Otherwise the text field would be hidden.
     * TODO: Move the view only if necessary (e.g. on iPhone 4)
     */
    @IBAction func enterTextField(_ textField: UITextField) {
        print("ClockViewController.\(#function): text field \(textField) is entered.");
        self.animateTextField(textField, distance: -60)
    }

    /**
     * If a text field is left and the keyboard disappears we have to should move
     * the view down again.
     * TODO: Move the view only if necessary (e.g. on iPhone 4)
     */
    @IBAction func leaveTextField(_ textField: UITextField) {
        print("ClockViewController.\(#function): text field \(textField) is left.");
        self.animateTextField(textField, distance: 60)
    }

    /**
     * This method moves the whole view down (if 'distance' is positiv) or up.
     * Use this method if keyboard appears and hides your text field.
     *
     * see http://www.osxentwicklerforum.de/index.php?page=Thread&threadID=13090
     */
    func animateTextField(_ textField: UITextField, distance: Int) {
        UIView.beginAnimations("anim", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(0.5)
        self.view.frame = self.view.frame.offsetBy(dx: CGFloat(0), dy: CGFloat(distance))
        UIView.commitAnimations()
    }

}
