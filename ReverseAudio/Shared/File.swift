//
//  File.swift
//  ReverseAudio
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2022/reverse-audio/
//
//  Created by Joseph Pagliaro on 1/16/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import Foundation

struct File: Identifiable {
    var url:URL
    var id = UUID()
}

