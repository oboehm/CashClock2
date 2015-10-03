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
//  (c)reated 05.04.15 by oliver (ob@cashclock.de)
//

import Foundation

/**
 * If you want to be updated by a new timer tick with the new amount of money
 * implement this protocol.
 */
public protocol ClockObserver {
    func update(time:Int, money:Double)
}
