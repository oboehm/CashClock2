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
//  Created by oliver on 21.10.15.
//  Copyright © 2015 Oliver Boehm. All rights reserved.
//

import Foundation


/**
* This protocol is placed here in this file because otherwise I got an
* strange compiler error
*/
protocol CashObserver {
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
class CashCalculator:NSObject {
    
    var numberOfPersons = 1
    var costPerHour = 40
    var totalCost = 0.0
    var startTime:NSTimeInterval = 0
    var currentTime:NSTimeInterval = 0
    var elapsedTime:NSTimeInterval = 0
    var timer:NSTimer? = nil
    var observers:[CashObserver] = []
    
    func addObserver(observer:CashObserver) -> Int {
        self.observers.append(observer)
        print("CashCalculator.\(__FUNCTION__): \(observer) is added as \(observers.count) observer.")
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
        print("CashCalculator.\(__FUNCTION__): timer is stopped.")
    }
    
    func continueTimer() {
        startTime = NSDate.timeIntervalSinceReferenceDate()
        currentTime = startTime
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self,
            selector: "updateTimeAndMoney", userInfo: nil, repeats: true)
        print("CashCalculator.\(__FUNCTION__): timer is started (again).")
    }
    
    func resetTimer() {
        elapsedTime = 0
        totalCost = 0.0
        print("CashCalculator.\(__FUNCTION__): timer is resetted.")
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

}
