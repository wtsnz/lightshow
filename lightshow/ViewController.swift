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

class ViewController: NSViewController {

    @IBOutlet weak var timeCodeLabel: NSTextField!
    var audioPlayer: EZAudioPlayer? = nil
    var audioFile: EZAudioFile? = nil
    
    @IBOutlet weak var audioPlotView: EZAudioPlotGL!
    
    @IBOutlet weak var waveformOverlayView: WaveformOverlayView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.audioPlotView.plotType = EZPlotType.Buffer
        self.audioPlotView.shouldFill = true
        self.audioPlotView.shouldMirror = true

        let url = NSBundle.mainBundle().URLForResource("magnets", withExtension: "mp3")
        self.openFileWithFilePathURL(url!)


        self.waveformOverlayView.delegate = self
        
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
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
        }
        
        self.audioPlayer = EZAudioPlayer(audioFile: self.audioFile!, delegate: self)
        self.audioFile?.getWaveformDataWithNumberOfPoints(4096, completion: { (test: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, length: Int32) -> Void in
            
            let te = test[0]
            self.audioPlotView.updateBuffer(te, withBufferSize: UInt32(length))
        })
    }
    
}

extension ViewController: EZAudioFileDelegate {
    
}

extension ViewController: EZAudioPlayerDelegate {
    
    func audioPlayer(audioPlayer: EZAudioPlayer!, updatedPosition framePosition: Int64, inAudioFile audioFile: EZAudioFile!) {
//        print("updated position \(framePosition)")
        self.waveformOverlayView.setCurrentPosition(framePosition)
        self.timeCodeLabel.stringValue = audioPlayer.formattedCurrentTime
    }
    
}

extension ViewController: WaveformOverlayViewDelegate {
    
    func waveformOverlayViewDidUpdatePlaybackPosition(waveformOverlayView: WaveformOverlayView, position: Int64) {
        self.audioPlayer?.seekToFrame(position)
    }
    
}

