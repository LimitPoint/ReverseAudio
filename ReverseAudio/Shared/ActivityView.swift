//
//  ActivityView.swift
//  ReverseAudio
//
//  Created by Joseph Pagliaro on 1/16/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import SwiftUI

struct ActivityView: View {
    
    @ObservedObject var reverseAudioObservable: ReverseAudioObservable
    
    var body: some View {
        VStack {
            ProgressView("Progress:", value: reverseAudioObservable.progress, total: 1)
                .padding(2)
                .frame(width: 100)
            
            if let audioURL = reverseAudioObservable.reversedAudioURL {
                Button("Play Reversed Audio", action: { 
                    reverseAudioObservable.playAudioURL(audioURL)
                }).padding(2)
            }
            else {
                Text("No reversed audio to play.")
                    .padding(2)
            }
            
            if let audioURL = reverseAudioObservable.reversedReversedAudioURL {
                Button("Play Reversed Reversed Audio", action: { 
                    reverseAudioObservable.playAudioURL(audioURL)
                }).padding(2)
            }
            else {
                Text("No reversed reversed audio to play.")
                    .padding(2)
            }
        }
        .padding(5)
    }
}

struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView(reverseAudioObservable: ReverseAudioObservable())
    }
}
