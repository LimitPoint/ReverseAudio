//
//  HeaderView.swift
//  ReverseAudio
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2022/reverse-audio/
//
//  Created by Joseph Pagliaro on 1/16/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import SwiftUI

struct HeaderView: View {
    
    @ObservedObject var reverseAudioObservable: ReverseAudioObservable
    
    var body: some View {
#if os(macOS)
        VStack {
            Text("Files generated into Documents folder")
                .fontWeight(.bold)
                .padding(2)
            Text("This app reverses and then reverses the reversed.")
            
            Button("Go to Documents", action: { 
                NSWorkspace.shared.open(reverseAudioObservable.documentsURL)
            }).padding(2)
        }
#else 
        Text("Files generated into Documents folder")
            .fontWeight(.bold)
            .padding(2)
#endif
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(reverseAudioObservable: ReverseAudioObservable())
    }
}
