//
//  ViewController.swift
//  project eye
//
//  Created by 陳鈞廷 on 2017/5/13.
//  Copyright © 2017年 陳鈞廷. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController, UIGestureRecognizerDelegate, SFSpeechRecognizerDelegate {
    
    @IBOutlet var tapView: UIView!
    
    var UserString: String?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "zh-TW"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest? //這個物件負責發起語音識別請求
    private var recognitionTask: SFSpeechRecognitionTask? //這個物件用於保存發起語音識別請求后的返回值
    private let audioEngine = AVAudioEngine() //這個物件引用了語音引擎，它負責提供錄音輸入。
    //語音輸出部分
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")

    func myTTS(mystring: String) {
        myUtterance = AVSpeechUtterance(string:mystring)
        myUtterance.rate = 0.4
        myUtterance.pitchMultiplier = 1.2
        myUtterance.postUtteranceDelay = 0.1
        myUtterance.volume = 1
        myUtterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        synth.speak(myUtterance)
    }
    
    func open(){
        let ReadString: String = "歡迎使用project eye，請輕觸螢幕一下以繼續"
        myTTS(mystring: ReadString)
    }
    //手勢
    var tapGesture = UITapGestureRecognizer()
    var FirstTapDone:Bool=false
    var count: Int = 0
    func TapTheScreen(_ sender: UITapGestureRecognizer){
        print("tap the screen")
        if FirstTapDone == true{
            if audioEngine.isRunning {
                audioEngine.stop()
                recognitionRequest?.endAudio()
                tapView.isUserInteractionEnabled = false
                
            } else {
                startRecording()
            }
            
        }
        else{
            FirstTapDone = true
            var ReadString:String = "本app使用語音辨識服務，當您開始說話前與結束說話時，請輕觸螢幕一下。"
            myTTS(mystring: ReadString)
            ReadString = "請問您要直接開啟相機進行辨識嗎？"
            myTTS(mystring: ReadString)
        }
    }
    
    //語音輸入部分
   
     //使用者的字串
    //錄音程式
    func startRecording() {
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }  //4
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        
        recognitionRequest.shouldReportPartialResults = true  //6
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            if result != nil {
                self.UserString = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
                //if self.UserString != nil { print(self.UserString!) }
                //else{
                //    print("no voice at all!!!")
                //}
            }
            
            if error != nil || isFinal {  //10
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.tapView.isUserInteractionEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()  //12
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
    }
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            do{
                try AVAudioSession.sharedInstance().setActive(true)
            }catch{
            }
        }catch{
        }
        //手勢
        tapGesture = UITapGestureRecognizer(target:self,action:#selector(ViewController.TapTheScreen(_:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        tapView.addGestureRecognizer(tapGesture)
        tapView.isUserInteractionEnabled = true
        
        
        
        speechRecognizer.delegate = self  //3
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isTapEnabled = false
            
            switch authStatus {  //5
            case .authorized:
                isTapEnabled = true
                
            case .denied:
                isTapEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isTapEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isTapEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.tapView.isUserInteractionEnabled = isTapEnabled
            }
        }
        open()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

