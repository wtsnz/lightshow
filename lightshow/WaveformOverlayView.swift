//
//  WaveformOverlayView.swift
//  lightshow
//
//  Created by Will Townsend on 13/02/16.
//  Copyright © 2016 Will Townsend. All rights reserved.
//

import Foundation
import Cocoa

protocol WaveformOverlayViewDelegate {
    func waveformOverlayViewDidUpdatePlaybackPosition(waveformOverlayView: WaveformOverlayView, position: Int64)
}

class WaveformOverlayView: NSView {
    
    var delegate: WaveformOverlayViewDelegate? = nil
    
    var totalFrames: Int64 = 0
    
    lazy var indicatorLayer: CALayer = {
        let indicatorLayer = CALayer()
        indicatorLayer.backgroundColor = NSColor.blackColor().CGColor
        return indicatorLayer
    }()
        
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.layer?.addSublayer(self.indicatorLayer)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.addSublayer(self.indicatorLayer)
    }
    
    override func mouseDown(event: NSEvent) {
        super.mouseDown(event)
        self.handleMouseEvent(event)
    }
    
    override func mouseDragged(event: NSEvent) {
        super.mouseDragged(event)
        self.handleMouseEvent(event)
    }
    
    func handleMouseEvent(event: NSEvent) {
        let point = self.convertPoint(event.locationInWindow, fromView: self.window!.contentView!)
        let percent = (100 / self.bounds.width) * point.x
        let position = (CGFloat(self.totalFrames) * percent) / 100
        NSLog("boundswidth: \(self.bounds.width), point.x: \(point.x), percent: \(percent), position: \(position)")
        self.delegate?.waveformOverlayViewDidUpdatePlaybackPosition(self, position: Int64(position))
    }
    
    func setCurrentPosition(position: Int64) {
        
        guard self.totalFrames != 0 else {
            return
        }
        
        let x = CGFloat(Int(CGFloat(self.bounds.width / CGFloat(self.totalFrames)) * CGFloat(position)))
        
        if x != self.indicatorLayer.frame.origin.x {
//            dispatch_async(dispatch_get_main_queue()) { () -> Void in
//                NSLog("x: \(x)")
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.indicatorLayer.frame = CGRectMake(CGFloat(x), 0, 1, self.bounds.height)
        CATransaction.commit()

//            }
        }
        
        
    }
    
}
