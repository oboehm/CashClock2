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
//  (c)reated by oliver on 03.04.15 (ob@cashclock.de)
//

import UIKit
import XCTest

class ClockCalculatorTests: XCTestCase, ClockObserver {
    
    var calculator = ClockCalculator()
    var updated = 0;

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        calculator.resetTimer()
        updated = 0;
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        NSUserDefaults.standardUserDefaults().removeObjectForKey("CashClock")
        print("ClockCalculatorTests.\(__FUNCTION__): test data deleted.")
        super.tearDown()
    }

    /**
     * This method will be called by the observed ClockCalculator.
     */
    func update(time:NSTimeInterval, money:Double) {
        updated++
    }
    
    /**
     * If the timer is resetted we expect to get '0' as elapsed time.
     */
    func testResetTimer() {
        calculator.resetTimer()
        XCTAssertEqual(calculator.elapsedTime, 0.0, "elapsedTime is not 0")
    }
    
    /**
     *  When we start the timer and measure then the elapsed time the time
     *  should be a positive value near 0.
     */
    func testStartTimer() {
        // This is an example of a performance test case.
        self.measureBlock() {
            self.calculator.startTimer()
            let elapsedTime = self.calculator.elapsedTime
            print("ClockCalculatorTests.\(__FUNCTION__): elapsedTime was \(elapsedTime)")
            XCTAssert(elapsedTime >= 0, "elapsedTime \(elapsedTime) is to small")
            XCTAssert(elapsedTime < 1000, "elapsedTime \(elapsedTime) is to big")
            XCTAssert(self.calculator.state == State.Started, "expected: state = Started")
        }
    }
    
    /**
     * Here we check the calculation. We use 36$ costs per hour because this
     * is 1 cent / second.
     */
    func testTotalCost() {
        calculator.numberOfPersons = 100
        calculator.costPerHour = 36
        calculator.startTimer()
        usleep(200000)
        calculator.stopTimer()
        print("ClockCalculatorTests.\(__FUNCTION__): costs = \(calculator.getMoney())"
            + " for \(calculator.getTime()) seconds")
        XCTAssertEqual(calculator.getMoney(), calculator.getTime(), "calculation is wrong")
    }
    
    /**
     * Here we test if this test class is notificated by a change triggered
     * by a timer inside the ClockCalculator class.
     */
    func testNotifications() {
        let i = calculator.addObserver(self)
        calculator.startTimer()
        usleep(310000)
        calculator.stopTimer()
        print("ClockCalculatorTests.\(__FUNCTION__): \(self) was updated \(updated) time(s).")
        calculator.removeObserver(i)
        XCTAssert(updated > 0, "update(..) was not called")
    }
    
    /**
     * If there are no data to load the program should not crash.
     */
    func testLoad() {
        calculator.load()
    }
    
    /**
     * We save and load the calculator data and test if the loaded data are the
     * the same as before.
     */
    func testSave() {
        calculator.numberOfPersons = 42;
        calculator.costPerHour = 4711;
        calculator.save();
        calculator.resetTimer();
        calculator.load();
        XCTAssertEqual(42, calculator.numberOfPersons, "data not loaded");
        XCTAssertEqual(4711, calculator.costPerHour, "data not loaded");
    }
    
    /**
     * Here we test the string repesentation of the ClockCalculator.
     */
    func testDescription() {
        let s = calculator.description
        XCTAssertEqual("1x40$x0s=0$ (init)", s, "wrong description")
    }

}
