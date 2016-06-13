//
//  ValueHolder.swift
//  SoundPlayer
//
//  Created by mst on 2016/06/26.
//  Copyright © 2016年 mst. All rights reserved.
//

import Foundation

class ValueHolder {
	var list: [Int] = []

	func update(value: Int) {
        if(list.isEmpty){
            list.append(value)
            return
        }
        
		list.append(value)
		if (list.count > 3) {
			list.removeAtIndex(0)
		}
	}

	func getAverage() -> Int {
		return Int(list.reduce(0, combine: +) / list.count)
	}
}
