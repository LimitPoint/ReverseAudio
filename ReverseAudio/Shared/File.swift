//
//  File.swift
//  ReverseAudio
//
//  Created by Joseph Pagliaro on 1/16/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import Foundation

struct File: Codable, Identifiable {
    var url:URL
    var id = UUID()
}

