//
//  ViewController.swift
//  recorder
//
//  Created by 長澤諭 on 2015/08/29.
//  Copyright (c) 2015年 Satoshi Nagasawa. All rights reserved.
//

import UIKit
// 必ずインポートする
import AVFoundation

class ViewController: UIViewController {
    
    // 各種ボタンの定数
    let BTN_RECORD = 0 // 録音
    let BTN_STOP = 1  // 停止
    let BTN_LISTEN = 2 // 再生/再生停止
    
    // 再生プレイヤー
    var _player = [AVAudioPlayer]()
    
    // AVAudionRecorderクラスを生成
    var recorder: AVAudioRecorder!
    var meterTimer: NSTimer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dx: CGFloat = (UIScreen.mainScreen().bounds.size.width - 320) / 2
        
        // 録音ボタンの生成
        let btnRecord = makeButton(CGRectMake(dx+55, 62, 100, 40),
            text: "録音", tag: BTN_RECORD)
        self.view.addSubview(btnRecord)
        
        // 停止ボタンの生成
        let btnStop = makeButton(CGRectMake(dx+165, 62, 100, 40),
            text: "停止", tag: BTN_STOP)
        self.view.addSubview(btnStop)
        
        // 再生/再生停止ボタンの生成
        let btnListen = makeButton(CGRectMake(dx+110, 100, 100, 40),
            text: "再生/再生停止", tag: BTN_LISTEN)
        self.view.addSubview(btnListen)
    }
    
    //　ボタンクリック時に呼ばれる
    func onClick(sender: UIButton) {
        // 録音ボタン押下時
        if sender.tag == BTN_RECORD {
            // 録音開始
            self.recordWithPermission(true)
        // 停止ボタン押下時
        } else if sender.tag == BTN_STOP {
            // レコーダーが生成されていなければreturnする
            if recorder == nil {
                return
            }
            
            println("stop")
            // 録音停止
            self.recorder.stop()
//            self.btnRecord.setTitle("Record", forState:.Normal)
            let session:AVAudioSession = AVAudioSession.sharedInstance()
            var error: NSError?
            if !session.setActive(false, error: &error) {
                println("could not make session inactive")
                if let e = error {
                    println(e.localizedDescription)
                    return
                }
            }
//            self.stopButton.enabled = false
//            self.recordButton.enabled = true
        } else if sender.tag == BTN_LISTEN {
            // 録音ファイルのリソースパスを取得(string)
            var docsDir = NSHomeDirectory().stringByAppendingPathComponent("Documents")
            let path = docsDir + "/Recorded.m4a"
            // 録音されたファイルがあるか確認
            var checkValidation = NSFileManager.defaultManager()
            println(checkValidation.fileExistsAtPath(path))
            if checkValidation.fileExistsAtPath(path) {
                // リソースパスをリソースURLに変換
                let url = NSURL.fileURLWithPath(path)
                // 再生プレイヤーを生成
                _player.append(AVAudioPlayer(contentsOfURL: url, error: nil))
                // BGMの再生と停止
                if !_player[0].playing {
                    _player[0].numberOfLoops = 999
                    _player[0].currentTime = 0
                    _player[0].play()
                } else {
                    _player[0].stop()
                }
            // リソースがなければリターンする
            } else {
                return
            }
        }
    }
    
    // ボタン生成メソッド
    func makeButton(frame: CGRect, text: NSString, tag: Int) -> UIButton {
        let button = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button.frame = frame
        button.setTitle(text as? String, forState: UIControlState.Normal)
        button.tag = tag
        button.addTarget(self, action: "onClick:",
            forControlEvents: UIControlEvents.TouchUpInside)
        return button
    }
    
    // レコーダーを生成する処理
    func setupRecorder() {
        
//        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask,true)
//        var docsDir: AnyObject = dirPaths[0]
//        var soundFilePath = docsDir.stringByAppendingPathComponent("Recorded.m4a")
        
        // Documentsディレクトリパスを取得
        var docsDir = NSHomeDirectory().stringByAppendingPathComponent("Documents")
        // Documentsディレクトリにm4aファイルを作成する準備
        var soundFilePath = docsDir.stringByAppendingPathComponent("Recorded.m4a")
        //こういうURLを作成するfile:///Users/nagasawasatoshi/Library/Developer/CoreSimulator/Devices/5FBBBD77-D17D-4B4F-A241-7A690228E0BD/data/Containers/Data/Application/6755ED72-94B6-470D-817E-82BD3CE57D16/Documents/Recorded.m4a
        // 録音データを保存する場所
        let soundFileURL = NSURL(fileURLWithPath: soundFilePath)
        
        var recordSettings = [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey : 44100.0
        ]
        
        // インスタンスを生成する
        var error: NSError?
        self.recorder = AVAudioRecorder(URL: soundFileURL!, settings: recordSettings as [NSObject : AnyObject], error: &error)
        if let e = error {
            println(e.localizedDescription)
        } else {
            // 停止ボタンを押した後の処理をデリゲート化（これはなぜだか分からない？？？）
            self.recorder.delegate = self
             // 録音中に音量をとるかどうか（true = とる）
            self.recorder.meteringEnabled = true
            // 録音ファイルの準備(すでにファイルが存在していれば上書きしてくれる)
            self.recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
            
        }
    }
    // 録音が可能か確認する処理
    func recordWithPermission(setup:Bool) {
        // 「AVAudioSession」インスタンスに対して音の扱いに関するいろいろなメソッドの実行が可能
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        // ios 8 and later
        // 「session」オブジェクトが「requestRecordPermission」メソッドを実装しているか「respondsToSelector」で確認
        if (session.respondsToSelector("requestRecordPermission:")) {
            // ユーザからマイクを使用する許可を取る
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    println("Permission to record granted")
                    // セッションを確立させる
                    self.setSessionPlayAndRecord()
                    // trueが入っているはず・・・
                    if setup {
                        // レコーダーを生成(これでself.recorderが宣言できる)
                        self.setupRecorder()
                    }
                    self.recorder.record()
                    // TODO:まだ未実装
//                    self.meterTimer = NSTimer.scheduledTimerWithTimeInterval(0.1,
//                        target:self,
//                        selector:"updateAudioMeter:",
//                        userInfo:nil,
//                        repeats:true)
                } else {
                    // 許可が得られなかった場合
                    println("Permission to record not granted")
                }
            })
        } else {
            // マイク使用許可のメソッドが使用iphoneでは実装されていない（古いiphone?）
            println("requestRecordPermission unrecognized")
        }
    }

    /* 
    セッションを確立させるメソッド
    */
    func setSessionPlayAndRecord() {
        // 「AVAudioSession」インスタンスに対して音の扱いに関するいろいろなメソッドの実行が可能
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        // NSErrorのオプショナル型を定義してそのアドレスを渡す
        var error: NSError?
        // アプリの音の扱い方を「PlayAndRecord」に設定（これで録音と再生が可能）
        if !session.setCategory(AVAudioSessionCategoryPlayAndRecord, error:&error) {
            // 機種が非対応の為、エラーを吐く
            println("could not set session category")
            if let e = error {
                println(e.localizedDescription)
            }
        }
        // sessionをアクティブ化
        if !session.setActive(true, error: &error) {
            // 機種が非対応の為、エラーを吐く
            println("could not make session active")
            if let e = error {
                println(e.localizedDescription)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // オーディオプレイヤーの生成
    func makeAudioPlayer() {
        // リソースURLの生成
    }
    
}

extension ViewController : AVAudioRecorderDelegate {
    // 録音が終わったら呼ばれるメソッド（recorder.stopメソッド後の処理）
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!,
        successfully flag: Bool) {
            println("録音終了 \(flag)")
//            recordButton.setTitle("Record", forState:.Normal)
            
            // iOS8 and later
            var alert = UIAlertController(title: "Recorder",
                message: "録音終了",
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "保存", style: .Default, handler: {action in
                println("保存した")
            }))
            alert.addAction(UIAlertAction(title: "やっぱり録音しない", style: .Default, handler: {action in
                println("保存しなかった")
                self.recorder.deleteRecording()
                self.recorder = nil
                
            }))
            // アラートを表示させる
            self.presentViewController(alert, animated:true, completion:nil)
    }
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder!,
        error: NSError!) {
            println("\(error.localizedDescription)")
    }
}

