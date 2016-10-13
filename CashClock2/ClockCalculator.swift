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
    func update(_ time:TimeInterval, money:Double)
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
    var startTime:TimeInterval = 0
    var currentTime:TimeInterval = 0
    var elapsedTime:TimeInterval = 0
    var timer:Timer = Timer()
    var observers:[ClockObserver] = []
    var state = State.Init
    
    /**
     * To get a better string representation for logging we override the
     * description function from the CustomStringConvertible protocoll.
     */
    override var description : String {
        return String(format: "%dx%f$x%ds=%.2f$ (%s)", numberOfPersons, costPerHour, elapsedTime, totalCost,
                      state.rawValue)
    }
    
    func addObserver(_ observer:ClockObserver) -> Int {
        self.observers.append(observer)
        print("ClockCalculator.\(#function): \(observer) is added as \(observers.count) observer.")
        return self.observers.count - 1
    }
    
    func removeObserver(_ i:Int) {
        self.observers.remove(at: i)
    }

    func startTimer() {
        resetTimer()
        continueTimer()
    }
    
    func stopTimer() {
        timer.invalidate()
        updateTimeAndMoney()
        print("ClockCalculator.\(#function): timer is stopped.")
    }
    
    func continueTimer() {
        startTime = Date.timeIntervalSinceReferenceDate
        currentTime = startTime
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
            selector: #selector(ClockCalculator.updateTimeAndMoney), userInfo: nil, repeats: true)
        print("ClockCalculator.\(#function): timer is started (again).")
    }
    
    func resetTimer() {
        elapsedTime = 0
        totalCost = 0.0
        print("ClockCalculator.\(#function): timer is resetted.")
    }
    
    /**
     * This is the method where the business logic happens. The costs of the
     * last interval is calculated and with the result the total costs and
     * elapsed time is updated.
     */
    func updateTimeAndMoney() {
        currentTime = Date.timeIntervalSinceReferenceDate
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
    func getTime() -> TimeInterval {
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
        self.costPerHour = decoder.decodeInteger(forKey: "costPerHour")
        self.numberOfPersons = decoder.decodeInteger(forKey: "numberOfPersons")
    }
    
    /**
     * This method is needed for the NSCoding protokoll.
     */
    func encode(with coder:NSCoder) {
        coder.encodeCInt(Int32(self.costPerHour), forKey: "costPerHour")
        coder.encodeCInt(Int32(self.numberOfPersons), forKey: "numberOfPersons")
    }
    
    /**
     * Save data.
     * see http://nshipster.com/nscoding/
     */
    func save() {
        let data = NSKeyedArchiver.archivedData(withRootObject: self)
        UserDefaults.standard.set(data, forKey: "CashClock")
        print("ClockCalculator.\(#function): CostPerHour=\(costPerHour), NumberOfPersons=\(numberOfPersons) saved.")
    }
    
    /**
     * Load data.
     * see http://nshipster.com/nscoding/
     */
    func load() {
        let defaults = UserDefaults.standard
        if let data = defaults.object(forKey: "CashClock") as? Data {
            if let clockData = NSKeyedUnarchiver.unarchiveObject(with: data) as? ClockCalculator {
                self.costPerHour = clockData.costPerHour;
                self.numberOfPersons = clockData.numberOfPersons;
                print("ClockCalculator.\(#function): CostPerHour=\(costPerHour), NumberOfPersons=\(numberOfPersons) loaded.")
            } else {
                print("ClockCalculator.\(#function): no calcuator data stored - nothing loaded.")
            }
        } else {
            print("ClockCalculator.\(#function): nothing loaded - no data found.")
        }
    }

}
