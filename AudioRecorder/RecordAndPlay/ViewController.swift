//
//  ViewController.swift
//  RecordAndPlay
//
//  Created by Nimble Chapps on 26/04/16.
//  Copyright © 2016 Pablo. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController , AVAudioRecorderDelegate , AVAudioPlayerDelegate {
    
    
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnRecord: UIButton!
    var audioRecorder:AVAudioRecorder!
    var audioPlayer : AVAudioPlayer!
    var contador = Counter()
    let isRecorderAudioFile = false
    let recordSettings = [AVSampleRateKey : NSNumber(float: Float(88200.0)),
        AVNumberOfChannelsKey : NSNumber(int: 1),
        AVEncoderAudioQualityKey : NSNumber(int: Int32(AVAudioQuality.Medium.rawValue))]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnPlay.enabled = false
    }
    
    //Metodo para guardar archivo en alguna carpeta en especifico.
    
    func directoryURL() -> NSURL? {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentDirectory = urls[0] as NSURL
        let filename = "palabra"+String(contador.count)+".wav"
        let soundURL = documentDirectory.URLByAppendingPathComponent(filename)
        contador.increment()
        print(soundURL)
        return soundURL
    }
    
    //Metodo para comenzar la grabacion
    
    @IBAction func doRecording(sender: AnyObject) {
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
                self.btnRecord.setTitle("Stop", forState: UIControlState.Normal)
                self.btnPlay.enabled = false
                try audioSession.setActive(true)
                audioRecorder.record()
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
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?){
        print(error.debugDescription)
    }
    internal func audioPlayerBeginInterruption(player: AVAudioPlayer){
        print(player.debugDescription)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

