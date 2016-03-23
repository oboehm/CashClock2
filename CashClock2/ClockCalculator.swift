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
//	(c)reated by oliver on 19.03.15 (ob@cashclock.de)

import Foundation

enum State : String, CustomStringConvertible {
    case Init = "init";
    case Started = "start";
    case Stopped = "stop";
    case Continued = "cont";
    
    // to be Printable
    var description : String {
        get {
            return self.rawValue
        }
    }
}

/**
 * This protocol is placed here in this file because otherwise I got an
 * strange compiler error
 */
protocol ClockObserver {
    func update(time:NSTimeInterval, money:Double)
}

/**
 * This ClockCalculator measures time and money.
 *
 * The average labor costs in Germany are about 31 Euros / hour
 * in general and 42,10 Euro / hour in the computer and communication
 * industrie. Because I think that this app will be mainly used in
 * this area we use about 40 Euro for initialization.
 *
 * http://www.heise.de/resale/artikel/Arbeitskosten-in-Deutschland-ueberdurchschnittlich-hoch-1830055.html
 * https://www.destatis.de/DE/Publikationen/StatistischesJahrbuch/VerdiensteArbeitskosten.pdf
 */
class ClockCalculator:NSObject, NSCoding {
    
    var numberOfPersons = 1
    var costPerHour = 40
    var totalCost = 0.0
    var startTime:NSTimeInterval = 0
    var currentTime:NSTimeInterval = 0
    var elapsedTime:NSTimeInterval = 0
    var timer:NSTimer = NSTimer()
    var observers:[ClockObserver] = []
    var state = State.Init
    
    /**
     * To get a better string representation for logging we override the
     * description function from the CustomStringConvertible protocoll.
     */
    override var description : String {
        return String(numberOfPersons) + "x" + String(costPerHour) + "$x"
            + String(Int(elapsedTime)) + "s=" + String(Int(totalCost)) + "$ ("
            + state.rawValue + ")"
    }
    
    /**
     * Dies ist das Gegenstueck zur description-Methode: hier werden die
     * Daten auseinandergenommen und damit die internen Attribute gesetzt.
     */
    func setData(data:String) {
        print("\(unsafeAddressOf(self))-ClockCalculator.\(__FUNCTION__): \(data) will be set.")
        // TODO: String parsen und Daten setzen
    }
    
    func addObserver(observer:ClockObserver) -> Int {
        self.observers.append(observer)
        print("\(unsafeAddressOf(self))-ClockCalculator.\(__FUNCTION__): \(observer) is added as observer \(observers.count) .")
        return self.observers.count - 1
    }
    
    func removeObserver(i:Int) {
        self.observers.removeAtIndex(i)
    }

    func startTimer() {
        resetTimer()
        continueTimer()
        state = State.Started
    }
    
    func stopTimer() {
        timer.invalidate()
        updateTimeAndMoney()
        state = State.Stopped
        print("\(unsafeAddressOf(self))-ClockCalculator.\(__FUNCTION__): timer is stopped.")
    }
    
    /**
     * Here we start the timer. The timer must be started in the main queue.
     * This is the reason why we use GCD here, see
     * https://osxentwicklerforum.de/index.php/Thread/30586-NSTimer-feuert-nicht/?postID=270700#post270700
     */
    func continueTimer() {
        self.startTime = NSDate.timeIntervalSinceReferenceDate()
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            // see https://osxentwicklerforum.de/index.php/Thread/30586-NSTimer-feuert-nicht/?postID=270700#post270700
            dispatch_async(dispatch_get_main_queue()) {
                self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self,
                    selector: "updateTimeAndMoney", userInfo: nil, repeats: true)
                //NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
                //self.timer.tolerance = 0.05
                //self.timer.fire()
                //print("\(unsafeAddressOf(self))-ClockCalculator.\(__FUNCTION__): \(self.timer) is continued.")
            }
        }
        self.state = State.Continued
    }
    
    func resetTimer() {
        elapsedTime = 0
        totalCost = 0.0
        state = State.Init
        timer.invalidate()
        print("\(unsafeAddressOf(self))-ClockCalculator.\(__FUNCTION__): timer is resetted.")
    }
    
    /**
     * This is the method where the business logic happens. The costs of the
     * last interval is calculated and with the result the total costs and
     * elapsed time is updated.
     */
    func updateTimeAndMoney() {
        currentTime = NSDate.timeIntervalSinceReferenceDate()
        //print("tick")
        let interval = currentTime - startTime
        assert(interval >= 0, "invalid startTime: \(startTime)")
        let intervalCost = Double(interval) * Double(costPerHour * numberOfPersons) / 3600.0
        totalCost += intervalCost
        elapsedTime += interval
        startTime = currentTime
        for obsrv in observers {
            obsrv.update(elapsedTime, money: totalCost)
        }
    }
    
    /**
     * The calculation of the total costs is now done in
     * updateTimeAndMoney().
     */
    func getTime() -> NSTimeInterval {
        return elapsedTime
    }
    
    /**
     * The calculation of the total costs is now done in
     * updateTimeAndMoney().
     */
    func getMoney() -> Double {
        return totalCost
    }
    
    
    
    /////   Persistence Section   //////////////////////////////////////////////////
    
    // see http://www.ioscampus.de/leicht-gemacht-daten-speichern/

    /**
     * This is the required init protocol.
     * see http://nshipster.com/nscoding/
     */
    required convenience init?(coder decoder: NSCoder) {
        self.init()
        self.costPerHour = decoder.decodeIntegerForKey("costPerHour")
        self.numberOfPersons = decoder.decodeIntegerForKey("numberOfPersons")
    }
    
    /**
     * This method is needed for the NSCoding protokoll.
     */
    func encodeWithCoder(coder:NSCoder) {
        coder.encodeInt(Int32(self.costPerHour), forKey: "costPerHour")
        coder.encodeInt(Int32(self.numberOfPersons), forKey: "numberOfPersons")
        coder.encodeObject(self.state.rawValue, forKey: "state")
    }
    
    /**
     * Save data.
     * see http://nshipster.com/nscoding/
     */
    func save() {
        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "CashClock")
        print("\(unsafeAddressOf(self))-ClockCalculator.\(__FUNCTION__): CostPerHour=\(costPerHour), NumberOfPersons=\(numberOfPersons) saved.")
    }
    
    /**
     * Load data.
     * see http://nshipster.com/nscoding/
     */
    func load() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let data = defaults.objectForKey("CashClock") as? NSData {
            if let clockData = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? ClockCalculator {
                self.costPerHour = clockData.costPerHour;
                self.numberOfPersons = clockData.numberOfPersons;
                print("\(unsafeAddressOf(self))-ClockCalculator.\(__FUNCTION__): CostPerHour=\(costPerHour), NumberOfPersons=\(numberOfPersons) loaded.")
            } else {
                print("\(unsafeAddressOf(self))-ClockCalculator.\(__FUNCTION__): no calcuator data stored - nothing loaded.")
            }
        } else {
            print("\(unsafeAddressOf(self))-ClockCalculator.\(__FUNCTION__): nothing loaded - no data found.")
        }
    }

}