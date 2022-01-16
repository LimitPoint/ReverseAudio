//
//  ContentView.swift
//  ReverseAudio
//
//  Created by Joseph Pagliaro on 1/16/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import SwiftUI

let skyBlue = Color(red: 0.4627, green: 0.8392, blue: 1.0, opacity:0.9)

struct ContentView: View {
    
    @ObservedObject var reverseAudioObservable:ReverseAudioObservable
    
    var body: some View {
        
        VStack {
            
            HeaderView(reverseAudioObservable: reverseAudioObservable)
            
            FileTableView(reverseAudioObservable: reverseAudioObservable)
            
            ActivityView(reverseAudioObservable: reverseAudioObservable)
        }
        .overlay(Group {
            if reverseAudioObservable.isReversing {          
                ProgressView("Reversing...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(skyBlue))
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(reverseAudioObservable: ReverseAudioObservable())
    }
}
