//
//  SwipeSelectingGestureRecognizer.swift
//  TileTime
//
//  Created by Shangen Zhang on 2019/3/26.
//  Copyright © 2019 Mi Cheng. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class SwipeSelectingGestureRecognizer: UIGestureRecognizer {

	private var beginPoint: CGPoint?

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesBegan(touches, with: event)
		beginPoint = touches.first?.location(in: self.view?.superview)
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
		guard let view = self.view?.superview,
			let touchPoint = touches.first?.location(in: view),
			let beginPoint = self.beginPoint else {
				return
		}
		let deltaY = abs(beginPoint.y - touchPoint.y)
		let deltaX = abs(beginPoint.x - touchPoint.x)
		if deltaX != 0 && deltaX / deltaY >= 2 {
			state = .began
			return
		}
        if self.state == .began {
            state = .changed
        }
        
	}
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        if state != .began || state != .changed {
            state = .cancelled
        } else {
            state = .ended
        }
    }

}
