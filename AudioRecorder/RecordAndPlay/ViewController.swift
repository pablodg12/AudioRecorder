//
//  ViewController.swift
//  RecordAndPlay
//
//  Created by Nimble Chapps on 26/04/16.
//  Copyright © 2016 Pablo. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController , AVAudioRecorderDelegate , AVAudioPlayerDelegate, UITextFieldDelegate {
    
    
    @IBOutlet weak var holiwi: UILabel!
    @IBOutlet weak var Basura: UILabel!
    @IBOutlet weak var counter: UITextField!
    @IBOutlet weak var textLabel: UITextField!
    @IBOutlet weak var btnWord: UISegmentedControl!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnRecord: UIButton!
    var audioRecorder:AVAudioRecorder!
    var audioPlayer : AVAudioPlayer!
    var contador = Counter()
    var mel = Mel()
    var word = "Photo"
    var value = "1"
    var variable : [Float] = []
    
    @IBAction func indexChanged(sender: UISegmentedControl) {
        switch btnWord.selectedSegmentIndex
        {
        case 0:
            self.word = "Photo"
            textLabel.text = "Photo";
        case 1:
            self.word = "Rec"
            textLabel.text = "Rec";
        case 2:
            self.word = "Stop"
            textLabel.text = "Stop";
        case 3:
            self.word = "Random"
            textLabel.text = "Random";
        default:
            break; 
        }
    }
    

    let isRecorderAudioFile = false
    let recordSettings = [AVSampleRateKey : NSNumber(float: Float(88200.0)),
        AVNumberOfChannelsKey : NSNumber(int: 1),
        
        AVEncoderAudioQualityKey : NSNumber(int: Int32(AVAudioQuality.Medium.rawValue))]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mel.fillMatrix("filter.txt",col: 128,row: 26)
        mel.fillMatrix("weigtha.txt",col: 14,row: 61)
        mel.fillMatrix("weigthb.txt",col: 4,row: 61)
        self.btnPlay.enabled = false
        self.counter.delegate = self;
        self.textLabel.delegate = self;
    }
    
    //Metodo para guardar archivo en alguna carpeta en especifico.
    
    func directoryURL() -> NSURL? {
        
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentDirectory = urls[0] as NSURL
        let filename = word+String(contador.count)+".wav"
        let soundURL = documentDirectory.URLByAppendingPathComponent(filename)
        contador.increment()
        counter.text = String(contador.count)
        return soundURL
    }
    
    //Metodo para comenzar la grabacion
    
    @IBAction func doRecording(sender: AnyObject) {
        self.value = counter.text!
        contador.set(Int(value)!)
        if sender.titleLabel!!.text == "Record" {
             let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                    try audioRecorder = AVAudioRecorder(URL: self.directoryURL()!,
                        settings: recordSettings)
                    audioRecorder.prepareToRecord()
                } catch {
              }
            do {
                self.btnPlay.enabled = false
                try audioSession.setActive(true)
                audioRecorder.recordForDuration(2)
                self.btnRecord.setTitle("Listo", forState: UIControlState.Normal)
            } catch {
          }
        }else{
            audioRecorder.stop()
            let audioSession = AVAudioSession.sharedInstance()
            do {
                self.btnRecord.setTitle("Record", forState: UIControlState.Normal)
                self.btnPlay.enabled = true
                try audioSession.setActive(false)
            } catch {
          }
        }
    }
    
    //Metodo para reproducir la ultima grabacion guardada.
    
    @IBAction func doPlay(sender: AnyObject) {
        if !audioRecorder.recording {
            self.audioPlayer = try! AVAudioPlayer(contentsOfURL: audioRecorder.url)
            self.audioPlayer.prepareToPlay()
            self.audioPlayer.delegate = self
            self.audioPlayer.play()
            variable = loadAudioSignal(audioRecorder.url).signal
            variable = mel.ft(variable)
            
            mel.setSignal(variable)
            
            mel.overlapping()
            
            mel.PreFourier()
            mel.performeFFt()
            mel.suma()
            
            mel.vecMatrixMult(mel.matrixFilter, tempVec: mel.result)
            mel.inverseDCT()
            
            mel.standarization()
            
            
            Basura.text = String(mel.final()[0])
        }
    }
    
    
    //MARK:- AudioRecordDelegate
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        print(flag)
    }
    
    //MARK:- AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        print(flag)
    }
    
    func loadAudioSignal(audioURL: NSURL) -> (signal: [Float], rate: Double, frameCount: Int) {
        let file = try! AVAudioFile(forReading: audioURL)
        let format = AVAudioFormat(commonFormat: .PCMFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)
        let buf = AVAudioPCMBuffer(PCMFormat: format, frameCapacity: UInt32(file.length))
        try! file.readIntoBuffer(buf) // You probably want better error handling
        let floatArray = Array(UnsafeBufferPointer(start: buf.floatChannelData[0], count:Int(buf.frameLength)))
        return (signal: floatArray, rate: file.fileFormat.sampleRate, frameCount: Int(file.length))
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?){
        print(error.debugDescription)
    }
    internal func audioPlayerBeginInterruption(player: AVAudioPlayer){
        print(player.debugDescription)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func recordAudio(sender: UIButton) {
        holiwi.text = String("holiwi")
    }


}

