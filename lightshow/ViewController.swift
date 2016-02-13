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
        return audioPlotView
    }()
    
    lazy var waveformOverlayView: WaveformOverlayView = {
        let waveformOverlayView = WaveformOverlayView(frame: CGRectMake(0, 0, 100, 100))
        return waveformOverlayView
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
                
//                self.audioPlotView.frame = CGRectMake(0, 0, CGFloat(audioFile.duration * 30), self.scrollView.contentView.frame.height)
                
                
                self.resizePlotView()
            }
            
        }
        
        self.audioPlayer = EZAudioPlayer(audioFile: self.audioFile!, delegate: self)
        self.audioFile?.getWaveformDataWithNumberOfPoints(4096, completion: { (test: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, length: Int32) -> Void in
            
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
    }
    
}

extension ViewController: EZAudioFileDelegate {
    
}

extension ViewController: EZAudioPlayerDelegate {
    
    func audioPlayer(audioPlayer: EZAudioPlayer!, updatedPosition framePosition: Int64, inAudioFile audioFile: EZAudioFile!) {
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.waveformOverlayView.setCurrentPosition(framePosition)
            self.timeCodeLabel.stringValue = "\(audioPlayer.formattedCurrentTime) \(framePosition)"
            let colour = colorForFrame(framePosition)
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

