//
//  FileTableView.swift
//  ReverseAudio
//
//  Created by Joseph Pagliaro on 1/16/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import Foundation
import SwiftUI

struct FileTableViewRowView: View {
    
    var file:File
    
    @ObservedObject var reverseAudioObservable: ReverseAudioObservable
    
    var body: some View {
        HStack {
            Text(file.url.lastPathComponent)
            
            Button("Play", action: {
                reverseAudioObservable.playAudioURL(file.url)
            })
                .buttonStyle(BorderlessButtonStyle())
            
            Button("Reverse", action: {
                reverseAudioObservable.reverseAudioURL(url: file.url)
            })
                .buttonStyle(BorderlessButtonStyle())
        }
    }
}

struct FileTableView: View {
    
    @ObservedObject var reverseAudioObservable: ReverseAudioObservable
    
    var body: some View {
        
        if reverseAudioObservable.files.count == 0 {
            Text("No Audio Files")
                .padding()
        }
        else {
#if os(macOS)
            List(reverseAudioObservable.files) {
                FileTableViewRowView(file: $0, reverseAudioObservable: reverseAudioObservable)
            }
#else
            NavigationView {
                List(reverseAudioObservable.files) {
                    FileTableViewRowView(file: $0, reverseAudioObservable: reverseAudioObservable)
                }
                .navigationTitle("Audio Files")
                
            }
            .navigationViewStyle(StackNavigationViewStyle())
#endif
        }
        
    }
}

struct FileTableView_Previews: PreviewProvider {
    static var previews: some View {
        FileTableView(reverseAudioObservable: ReverseAudioObservable())
    }
}
