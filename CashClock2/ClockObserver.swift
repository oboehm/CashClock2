//
//  ClockObserver.swift
//  CashClock2
//
//  Created by oliver on 05.04.15.
//  Copyright (c) 2015 Oliver Böhm. All rights reserved.
//

import Foundation

/**
 * If you want to be updated by a new timer tick with the new amount of money
 * implement this protocol.
 */
public protocol ClockObserver {
    func update(time:Int, money:Double)
}
