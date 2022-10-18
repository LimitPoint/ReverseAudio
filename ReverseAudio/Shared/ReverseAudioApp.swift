//
//  ReverseAudioApp.swift
//  ReverseAudio
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2022/reverse-audio/
//
//  Created by Joseph Pagliaro on 1/16/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import SwiftUI

@main
struct ReverseAudioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(reverseAudioObservable: ReverseAudioObservable())
        }
    }
}
