//
//  ReverseAudioObservable.swift
//  ReverseAudio
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2022/reverse-audio/
//
//  Created by Joseph Pagliaro on 1/16/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import Foundation
import AVFoundation

let kAudioFilesSubdirectory = "Audio Files"
let kAudioExtensions: [String] = ["aac", "m4a", "aiff", "aif", "wav", "mp3", "caf", "m4r", "flac"]

class ReverseAudioObservable: ObservableObject  {
    
    @Published var files:[File]
    
    @Published var reversedAudioURL:URL?
    @Published var reversedReversedAudioURL:URL?
    
    @Published var progress:Float = 0
    @Published var isReversing:Bool = false
    
    var documentsURL:URL
    
    var audioPlayer: AVAudioPlayer?
    
    let reverseAudio = ReverseAudio()
    
    func reverse(url:URL, saveTo:String, completion: @escaping (Bool, URL, String?) -> ()) {
        
        let reversedURL = documentsURL.appendingPathComponent(saveTo)
        
        let asset = AVAsset(url: url)
        
        reverseAudio.reverseAudio(asset: asset, destinationURL: reversedURL, progress: { value in
            DispatchQueue.main.async {
                self.progress = value
            }
        }) { (success, failureReason) in
            completion(success, reversedURL, failureReason)
        }
    }
    
    func reverseAudioURL(url:URL) {
        
        progress = 0
        isReversing = true
        
        reverse(url: url, saveTo: "REVERSED.wav") { (success, reversedURL, failureReason) in
            
            if success {
                
                print("SUCCESS! - reversed URL = \(reversedURL)")
                
                self.reverse(url: reversedURL, saveTo: "REVERSED-REVERSED.wav") { (success, reversedURL, failureReason) in
                    
                    if success {
                        
                        print("SUCCESS! - reversed reversed URL = \(reversedURL)")
                        self.completionSound()
                    }
                    DispatchQueue.main.async {
                        self.progress = 0
                        self.reversedReversedAudioURL = reversedURL
                        self.isReversing = false
                    }
                }
            }
            else {
                DispatchQueue.main.async {
                    self.isReversing = false
                }
            }
            DispatchQueue.main.async {
                self.progress = 0
                self.reversedAudioURL = reversedURL
            }
        } 
    }
    
    func loadPlayAudioURL(forResource:String, withExtension: String) {
        
        var audioURL:URL?
        
        if let url = Bundle.main.url(forResource: forResource, withExtension: withExtension, subdirectory: kAudioFilesSubdirectory) {
            audioURL = url
        }
        
        if let audioURL = audioURL {
            playAudioURL(audioURL)
        }
        else {
            print("Can't load audio url!")
        }
    }
    
    func completionSound() {
        if let url = Bundle.main.url(forResource: "Echo", withExtension: "m4a") {
            playAudioURL(url)
        }
    }
    
    func playAudioURL(_ url:URL) {
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)         
            
            if let audioPlayer = audioPlayer {
                audioPlayer.prepareToPlay()
                audioPlayer.play()
            }
            
        } catch let error {
            print(error.localizedDescription)
        }
        
    }
    
    init() {
        let fm = FileManager.default
        documentsURL = try! fm.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        self.files = []
        
        for audioExtension in kAudioExtensions {
            if let urls = Bundle.main.urls(forResourcesWithExtension: audioExtension, subdirectory: kAudioFilesSubdirectory) {
                for url in urls {
                    self.files.append(File(url: url))
                }
            }
        }
        
        self.files.sort(by: { $0.url.lastPathComponent > $1.url.lastPathComponent })
        
    }
}
