//
//  ViewController.swift
//  lightshow
//
//  Created by Will Townsend on 13/02/16.
//  Copyright © 2016 Will Townsend. All rights reserved.
//

import Cocoa
import SnapKit
import EZAudio
import LIFXKit

class View: NSView {
    
    
    
}

class LineView2: NSView {
    
    var path: NSBezierPath = NSBezierPath()
    var points: [CGFloat] = []
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(event: NSEvent) {
        super.mouseDown(event)
        
        let point = self.convertPoint(event.locationInWindow, fromView: self.window!.contentView!)
        self.path.lineToPoint(point)
//        self.setNeedsDisplay(true)
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        self.path.lineWidth = 3
        NSColor.blackColor().set()
        self.path.stroke()
        
    }
    
}

class LineView : NSView {
    
    var points = [CGPoint]()
    
    var newLinear = NSBezierPath()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        newLinear.moveToPoint(CGPointMake(0, 0))
        
        points.append(CGPointZero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(dirtyRect: NSRect) {
        NSColor.redColor().set()
        
        let path = NSBezierPath()
        for (index, point) in self.points.enumerate() {
            
            if index == 0 {
                path.moveToPoint(point)
            } else {
                path.lineToPoint(point)
            }
            
        }
        
        path.lineWidth = 1
        path.stroke()
    }
    
    func removeLastPoint() {
        self.points.removeLast()
        needsDisplay = true
    }
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        var lastPt = self.convertPoint(theEvent.locationInWindow, fromView: self.window!.contentView!)
        lastPt.x -= frame.origin.x
        lastPt.y -= frame.origin.y
        
        self.points.append(lastPt)
        
//        newLinear.lineToPoint(lastPt)
        needsDisplay = true
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        super.mouseDragged(theEvent)
        
//        newLinear.
        
        var newPt = self.convertPoint(theEvent.locationInWindow, fromView: self.window!.contentView!)
        newPt.x -= frame.origin.x
        newPt.y -= frame.origin.y
        
//        var lastPoint = self.points.last!
//        lastPoint = newPt
        self.points[self.points.count - 1] = newPt
        
//        let test = self.pointForXPosition(100)
        
//        newLinear.lineToPoint(newPt)
        needsDisplay = true
    }
    
    func brightnessForPosition(position: CGFloat) -> Float {
        
        return 0.5
    }
    
    func pointForXPosition(x: CGFloat) -> CGPoint {
        
        if self.points.count == 0 {
            return CGPointZero
        }
        
        let lastPointIndex = self.points.count - 1
        
        if x <= 0.0 {
            return self.points[0]
        }
        
        if x >= self.points[lastPointIndex].x {
            return self.points[lastPointIndex]
        }
        
        var index = 1
        
        while index < self.points.count && x > self.points[index].x {
            index++
        }
        
        let point1 = self.points[index - 1]
        let point2 = self.points[index]
        
        let dy = point2.y - point1.y
        let dx = (point2.x - point1.x)
        
        let slope = dy / dx
        
        let y = (slope * (x - point1.x)) + point1.y
        
        NSLog("dy: \(dy), dx: \(dx), y: \(y)")
        
        return CGPointMake(x, y)
    }
    
}


class ViewController: NSViewController {
    
    @IBOutlet weak var scrollView: NSScrollView!
    
    @IBOutlet weak var timeCodeLabel: NSTextField!
    var audioPlayer: EZAudioPlayer? = nil
    var audioFile: EZAudioFile? = nil
    
    lazy var audioPlotView: EZAudioPlot = {
        let audioPlotView = EZAudioPlot(frame: CGRectMake(0, 0, 100, 100))
        audioPlotView.plotType = EZPlotType.Buffer
        audioPlotView.shouldFill = true
        audioPlotView.shouldMirror = true
        audioPlotView.addSubview(self.waveformOverlayView)
        audioPlotView.addSubview(self.lineOverlayView)
        return audioPlotView
    }()
    
    lazy var waveformOverlayView: WaveformOverlayView = {
        let waveformOverlayView = WaveformOverlayView(frame: CGRectMake(0, 0, 100, 100))
        return waveformOverlayView
    }()
    
    lazy var lineOverlayView: LineView = {
        let lineOverlayView = LineView(frame: CGRectMake(0, 0, 100, 100))
        lineOverlayView.wantsLayer = true
        lineOverlayView.layer?.backgroundColor = NSColor.blueColor().colorWithAlphaComponent(0.2).CGColor
        return lineOverlayView
    }()
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSEvent.addLocalMonitorForEventsMatchingMask(.KeyDownMask) { (aEvent) -> NSEvent? in
            self.keyDown(aEvent)
            return aEvent
        }
        
        self.waveformOverlayView.delegate = self
        
        LFXClient.sharedClient().localNetworkContext.addNetworkContextObserver(self)
        LFXClient.sharedClient().localNetworkContext.allLightsCollection.addLightCollectionObserver(self)
        

        self.scrollView.documentView = self.audioPlotView

        let url = NSBundle.mainBundle().URLForResource("magnets", withExtension: "mp3")
        self.openFileWithFilePathURL(url!)
        
        
        
//        dispatch_async(dispatch_get_main_queue()) { () -> Void in
//        self.scrollView.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 20))
//        
//        self.scrollView.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 20))
//        
//        self.scrollView.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 20))
//        
//        self.scrollView.addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 20))
//        }
//        self.scrollView.snp_makeConstraints { (make) -> Void in
//            make.leading.equalTo(self.view)
//            make.trailing.equalTo(self.view)
//            make.top.equalTo(self.view).offset(100)
//            make.bottom.equalTo(self.view)
//        }
        
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func keyDown(theEvent: NSEvent) {
//        super.keyDown(theEvent)
        
        NSLog("\(theEvent.keyCode)")
        
        if theEvent.keyCode == 49 {
             self.playAction(self)
        }
    }
    
    
    @IBAction func deleteLastLineAction(sender: AnyObject) {
        
        self.lineOverlayView.removeLastPoint()
        
    }
    
    @IBAction func toggleLineAction(sender: AnyObject) {
        
        self.lineOverlayView.hidden = !self.lineOverlayView.hidden
        
    }
    
    
    @IBAction func playAction(sender: AnyObject) {
        
        guard let audioPlayer = self.audioPlayer else {
            return
        }
        
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
    }
    
    @IBAction func startAction(sender: AnyObject) {
        
        guard let audioPlayer = self.audioPlayer else {
            return
        }
        
        audioPlayer.seekToFrame(0)
        
    }
    
    @IBAction func openFileAction(sender: AnyObject) {
        
        let openFileDialogue = NSOpenPanel()
        openFileDialogue.canChooseFiles = true
        openFileDialogue.canChooseDirectories = false
        openFileDialogue.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                //Do what you will
                //If there's only one URL, surely 'openPanel.URL'
                //but otherwise a for loop works
                if let url = openFileDialogue.URL {
                    self.openFileWithFilePathURL(url)
                }
            }
        }
        
    }
    
    func openFileWithFilePathURL(filePathURL: NSURL) {
        self.audioFile = EZAudioFile(URL: filePathURL, delegate: self)
        
        if let audioFile = self.audioFile {
            self.waveformOverlayView.totalFrames = audioFile.totalFrames
            
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.resizePlotView()
            }
            
        }
        
        self.audioPlayer = EZAudioPlayer(audioFile: self.audioFile!, delegate: self)
        self.audioFile?.getWaveformDataWithNumberOfPoints(4096 + 4096, completion: { (test: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, length: Int32) -> Void in
            
            let te = test[0]
            self.audioPlotView.updateBuffer(te, withBufferSize: UInt32(length))
        })
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        self.resizePlotView()
        
    }
    
    func resizePlotView() {
        
        var bounds = self.audioPlotView.bounds
        if let audioFile = self.audioFile {
            bounds.size.width = CGFloat(audioFile.duration * 60)
        }
        bounds.size.height = self.scrollView.contentView.frame.height
        self.audioPlotView.frame = bounds
        self.scrollView.documentView?.setFrameSize(bounds.size)
        self.waveformOverlayView.frame = bounds
        self.lineOverlayView.frame = bounds
    }
    
}

extension ViewController: EZAudioFileDelegate {
    
}

extension ViewController: EZAudioPlayerDelegate {
    
    func audioPlayer(audioPlayer: EZAudioPlayer!, updatedPosition framePosition: Int64, inAudioFile audioFile: EZAudioFile!) {
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.waveformOverlayView.setCurrentPosition(framePosition)
            self.timeCodeLabel.stringValue = "\(audioPlayer.formattedCurrentTime) \(framePosition)"
            
            let point = self.lineOverlayView.pointForXPosition(self.waveformOverlayView.indicatorLayer.frame.origin.x)
            let value = ((100 / self.lineOverlayView.frame.height) * point.y) / 100
            let colour = LFXHSBKColor(hue: 120, saturation: 1, brightness: value, kelvin: 3000)
//            let colour = colorForFrame(framePosition)
            LFXClient.sharedClient().localNetworkContext.allLightsCollection.setColor(colour)
            
            
            
        }
        
    }
    
}

extension ViewController: WaveformOverlayViewDelegate {
    
    func waveformOverlayViewDidUpdatePlaybackPosition(waveformOverlayView: WaveformOverlayView, position: Int64) {

        
        
        self.audioPlayer?.seekToFrame(position)
        
        
//        setLightsToRandomColour()
        
    }
    
}

extension ViewController: LFXLightCollectionObserver {
    
    func lightCollection(lightCollection: LFXLightCollection!, didAddLight light: LFXLight!) {
        NSLog("did add light: \(light)")
    }
    
}

extension ViewController: LFXNetworkContextObserver {
    
    func networkContextDidConnect(networkContext: LFXNetworkContext!) {
        NSLog("connected")
    }
    
}

func setLightsToRandomColour() {
    let colour = LFXHSBKColor(hue: CGFloat(drand48()) * 360, saturation: CGFloat((drand48()*100)/100.0), brightness: CGFloat((drand48()*100)/100.0), kelvin: 3000)
    
    LFXClient.sharedClient().localNetworkContext.allLightsCollection.setColor(colour)
}


func colorForFrame(frame: Int64) -> LFXHSBKColor {
    
    if frame < 500713 {
        return LFXHSBKColor(hue: 120, saturation: 1, brightness: 0.2, kelvin: 3000)
    } else if frame < 513070 {
        return LFXHSBKColor(hue: 180, saturation: 1, brightness: 1.0, kelvin: 3000)
    } else if frame < 531399 {
        return LFXHSBKColor(hue: 120, saturation: 1, brightness: 0.2, kelvin: 3000)
    } else if frame < 539013 {
        return LFXHSBKColor(hue: 180, saturation: 1, brightness: 1.0, kelvin: 3000)
    } else if frame < 559013 {
        return LFXHSBKColor(hue: 120, saturation: 1, brightness: 0.2, kelvin: 3000)
    } else if frame < 567546 {
        return LFXHSBKColor(hue: 180, saturation: 1, brightness: 1.0, kelvin: 3000)
    } else if frame < 575177 {
        return LFXHSBKColor(hue: 120, saturation: 1, brightness: 0.2, kelvin: 3000)
    } else {
        return LFXHSBKColor(hue: 120, saturation: 1, brightness: 0.0, kelvin: 3000)
    }
    //539955
}

