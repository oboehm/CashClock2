//
//  ClockCalculatorModel.swift
//  CashClock2
//
//  Created by oliver on 19.03.15.
//  Copyright (c) 2015 Oliver Böhm. All rights reserved.
//

import Foundation

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
    var timer:NSTimer? = nil
    var observers:[ClockObserver] = []
    
    func addObserver(observer:ClockObserver) -> Int {
        self.observers.append(observer)
        println("ClockCalculator.\(__FUNCTION__): \(observer) is added as \(observers.count) observer.")
        return self.observers.count - 1
    }
    
    func removeObserver(i:Int) {
        self.observers.removeAtIndex(i)
    }

    func startTimer() {
        resetTimer()
        continueTimer()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        updateTimeAndMoney()
        println("ClockCalculator.\(__FUNCTION__): timer is stopped.")
    }
    
    func continueTimer() {
        startTime = NSDate.timeIntervalSinceReferenceDate()
        currentTime = startTime
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self,
            selector: "updateTimeAndMoney", userInfo: nil, repeats: true)
        println("ClockCalculator.\(__FUNCTION__): timer is started (again).")
    }
    
    func resetTimer() {
        elapsedTime = 0
        totalCost = 0.0
        println("ClockCalculator.\(__FUNCTION__): timer is resetted.")
    }
    
    /**
     * This is the method where the business logic happens. The costs of the
     * last interval is calculated and with the result the total costs and
     * elapsed time is updated.
     */
    func updateTimeAndMoney() {
        currentTime = NSDate.timeIntervalSinceReferenceDate()
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
    required convenience init(coder decoder: NSCoder) {
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
    }
    
    /**
     * Save data.
     * see http://nshipster.com/nscoding/
     */
    func save() {
        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "CashClock")
        println("ClockCalculator.\(__FUNCTION__): CostPerHour=\(costPerHour), NumberOfPersons=\(numberOfPersons) saved.")
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
                println("ClockCalculator.\(__FUNCTION__): CostPerHour=\(costPerHour), NumberOfPersons=\(numberOfPersons) loaded.")
            } else {
                println("ClockCalculator.\(__FUNCTION__): no calcuator data stored - nothing loaded.")
            }
        } else {
            println("ClockCalculator.\(__FUNCTION__): nothing loaded - no data found.")
        }
    }

}