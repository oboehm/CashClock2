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

enum State : String, CustomStringConvertible {
    case Init = "initialized";
    case Started = "started";
    case Stopped = "stopped";
    
    // to be Printable
    var description : String {
        get {
            return self.rawValue
        }
    }
}

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
    var state = State.Init

    /**
    * After the vew is loaded the used ClockCalculator is allocated and set up.
    * Also we set the property 'delegate' for internal text field
    * (see "Programmieren fuer iPhone und iPad", p. 279).
    *
    * NOTE: For the iAds facility you need internet access. So be sure network
    * is available if you want to test. Otherwise the iAd banner does not appear!
    */
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.canDisplayBannerAds = true
        calculator.load()
        self.populateValues()
        updateNumberOfPersons(calculator.numberOfPersons)
        updateCostPerHour(calculator.costPerHour)
        calculator.addObserver(self)
        self.registerForApplicationWillTerminate()
    }
    
    /**
     * We want to be noticed if aplication will terminate.
     * from: http://stackoverflow.com/questions/2432536/applicationwillterminate-delegate-or-view
     */
    private func registerForApplicationWillTerminate() {
        let app = UIApplication.sharedApplication()
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "applicationWillTerminate:",
            name: UIApplicationWillTerminateNotification,
            object: app)
    }
    
    func applicationWillTerminate(notification:NSNotification?) {
        calculator.save()
        print("ClockViewController.\(__FUNCTION__): \(notification) terminated.")
    }

    /**
     * This function populates values for some controls. The values which are
     * assigned for the fields will be displayed with localization format.
     * from: http://rshankar.com/internationalization-and-localization-of-apps-in-xcode-6-and-swift/
     */
    private func populateValues() {
        self.initCostLabel()
    }
    
    private func initCostLabel() {
        let numberFormatter = NSNumberFormatter()
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
    @IBAction func clickNumberOfPersonStepper(sender: UIStepper) {
        let value = sender.value
        calculator.numberOfPersons = Int(value)
        updateNumberOfPersons(Int(value))
    }
    
    private func updateNumberOfPersons(value: Int) {
        print("ClockViewController.\(__FUNCTION__): number of persons is set to \(value)")
        calculator.numberOfPersons = value
        stepperMemberCount.value = Double(calculator.numberOfPersons)
        textFieldMemberCount.text = String(calculator.numberOfPersons)
    }
    
    private func updateCostPerHour(value: Int) {
        print("ClockViewController.\(__FUNCTION__): cost per hour is set to \(value)")
        calculator.costPerHour = value
        textFieldCostPerHour.text = String(value)
    }

    /**
    * Her we start the timer. The code was first written with the help of
    * http://www.cocoa-coding.de/timer/timer.html and was then transfered
    * to Swift with the help of
    * http://rshankar.com/simple-stopwatch-app-in-swift/ .
    */
    @IBAction func clickStartStop(sender: AnyObject) {
        print("ClockViewController.\(__FUNCTION__): start/stop button pressed in state \(state)")
        switch (state) {
        case .Init:                 // "Start" was pressed
            calculator.startTimer()
            showStopButton()
            break
        case .Started:              // "Stop" was pressed
            calculator.stopTimer()
            startStopButton.setTitle(NSLocalizedString("continue", comment:"cont"),
                forState: UIControlState.Normal)
            startStopButton.setTitleColor(UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0),
                forState: UIControlState.Normal)
            enable(resetButton)
            state = State.Stopped
            break;
        case .Stopped:              // "continue" / "weiter" was pressed
            calculator.continueTimer()
            showStopButton()
            break
        }
    }
    
    @IBAction func clickReset(sender: AnyObject) {
        resetTimer()
        resetStartButton()
        state = State.Init
    }
    
    func resetTimer() {
        calculator.resetTimer()
        update(0.0, money: 0.0)
    }
    
    func resetStartButton() {
        startStopButton.setTitle(NSLocalizedString("start", comment:"start"),
            forState: UIControlState.Normal)
    }
    
    func showStopButton() {
        startStopButton.setTitle(NSLocalizedString("stop", comment:"stop"),
            forState: UIControlState.Normal)
        startStopButton.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
        disable(resetButton)
        state = State.Started
    }
    
    func disable(button: UIButton) {
        button.enabled = false
        button.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
    }
    
    func enable(button: UIButton) {
        button.enabled = true
        button.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
    }
    
    /**
     * This method will be called by the observed ClockCalculator.
     */
    func update(time:NSTimeInterval, money:Double) {
        updateElapsedTime(Int(time))
        updateElapsedMoney(money)
    }

    private func updateElapsedTime(time:Int) {
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = time / 3600
        self.displayTimeLabel.text = NSString(format: "%.2d:%.2d:%.2d", hours, minutes, seconds) as String
    }
    
    private func updateElapsedMoney(money:Double) {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        self.displayMoneyLabel.text = formatter.stringFromNumber(money)
        //self.displayMoneyLabel.text = NSString(format: "%4.2f €", money) as String
    }
    
    
    
    /////   Keyboard Handling   ////////////////////////////////////////////////////

    /**
     * To end editing and to let the keyboard disappear we override this
     * method from UITextViewDelegate.
     * see http://theapplady.net/workshop-9-hide-the-devices-keyboard/
     */
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("ClockViewController.\(__FUNCTION__): User tapped in the background.");
        endEditingMemberCount()
        endEditingCostPerHour()
    }
    
    private func endEditingMemberCount() {
        var n = calculator.numberOfPersons
        textFieldMemberCount.endEditing(true)
        if !textFieldMemberCount.text!.isEmpty {
            n = Int(textFieldMemberCount.text!)!
        }
        print("ClockViewController.\(__FUNCTION__): Member count is set to \(n).");
        updateNumberOfPersons(n)
    }
    
    private func endEditingCostPerHour() {
        var n = calculator.costPerHour
        textFieldCostPerHour.endEditing(true)
        if !textFieldCostPerHour.text!.isEmpty {
            n = Int(textFieldCostPerHour.text!)!
        }
        print("ClockViewController.\(__FUNCTION__): Cost per hour is set to \(n).");
        updateCostPerHour(n)
    }
    
    /**
     * If a text field is entered and the keyboard appears we have to move up the
     * view. Otherwise the text field would be hidden.
     * TODO: Move the view only if necessary (e.g. on iPhone 4)
     */
    @IBAction func enterTextField(textField: UITextField) {
        print("ClockViewController.\(__FUNCTION__): text field \(textField) is entered.");
        self.animateTextField(textField, distance: -60)
    }

    /**
     * If a text field is left and the keyboard disappears we have to should move
     * the view down again.
     * TODO: Move the view only if necessary (e.g. on iPhone 4)
     */
    @IBAction func leaveTextField(textField: UITextField) {
        print("ClockViewController.\(__FUNCTION__): text field \(textField) is left.");
        self.animateTextField(textField, distance: 60)
    }

    /**
     * This method moves the whole view down (if 'distance' is positiv) or up.
     * Use this method if keyboard appears and hides your text field.
     *
     * see http://www.osxentwicklerforum.de/index.php?page=Thread&threadID=13090
     */
    func animateTextField(textField: UITextField, distance: Int) {
        UIView.beginAnimations("anim", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(0.5)
        self.view.frame = CGRectOffset(self.view.frame, CGFloat(0), CGFloat(distance))
        UIView.commitAnimations()
    }

}
