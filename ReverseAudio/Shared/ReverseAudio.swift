//
//  ReverseAudio.swift
//  ReverseAudio
//
//  Created by Joseph Pagliaro on 1/16/22.
//  Copyright © 2022 Limit Point LLC. All rights reserved.
//

import Foundation
import AVFoundation
import CoreServices

let kAudioReaderSettings = [
    AVFormatIDKey: Int(kAudioFormatLinearPCM) as AnyObject,
    AVLinearPCMBitDepthKey: 16 as AnyObject,
    AVLinearPCMIsBigEndianKey: false as AnyObject,
    AVLinearPCMIsFloatKey: false as AnyObject,
    //AVNumberOfChannelsKey: 1 as AnyObject, // can set to read one channel only to avoid extracting only 1 later
    AVLinearPCMIsNonInterleaved: false as AnyObject]

let kAudioWriterExpectsMediaDataInRealTime = false
let kReverseAudioQueue = "com.limit-point.reverse-audio-queue"

extension Array {
    func blocks(size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

class ReverseAudio {
    
    func audioReader(asset:AVAsset, outputSettings: [String : Any]?) -> (audioTrack:AVAssetTrack?, audioReader:AVAssetReader?, audioReaderOutput:AVAssetReaderTrackOutput?) {
        
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            if let audioReader = try? AVAssetReader(asset: asset)  {
                let audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
                return (audioTrack, audioReader, audioReaderOutput)
            }
        }
        
        return (nil, nil, nil)
    }
    
    func extractSamples(_ sampleBuffer:CMSampleBuffer) -> [Int16]? {
        
        var blockBuffer: CMBlockBuffer? = nil
        let audioBufferList: UnsafeMutableAudioBufferListPointer = AudioBufferList.allocate(maximumBuffers: 1)
        
        guard CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: audioBufferList.unsafeMutablePointer,
            bufferListSize: AudioBufferList.sizeInBytes(maximumBuffers: 1),
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer
        ) == noErr else {
            return nil
        }
        
        if let data: UnsafeMutableRawPointer = audioBufferList.unsafePointer.pointee.mBuffers.mData {
            
            let sizeofInt16 = MemoryLayout<Int16>.size
            let dataSize = audioBufferList.unsafePointer.pointee.mBuffers.mDataByteSize
            
            let dataCount = Int(dataSize) / sizeofInt16
            
            var sampleArray : [Int16] = []
            let ptr = data.bindMemory(to: Int16.self, capacity: dataCount)
            let buf = UnsafeBufferPointer(start: ptr, count: dataCount)
            sampleArray.append(contentsOf: Array(buf))
            
            return sampleArray
        }
        
        return nil
    }
    
    func readAndReverseAudioSamples(asset:AVAsset) -> (Int, Int, [Int16])? {
        
        let (_, reader, readerOutput) = self.audioReader(asset:asset, outputSettings: kAudioReaderSettings)
        
        guard let audioReader = reader,
              let audioReaderOutput = readerOutput
        else {
            return nil
        }
        
        if audioReader.canAdd(audioReaderOutput) {
            audioReader.add(audioReaderOutput)
        }
        else {
            return nil
        }
        
        var bufferSize:Int = 0
        var sampleRate:Int = 0
        var audioSamples:[Int16] = []
        
        if audioReader.startReading() {
            
            while audioReader.status == .reading {
                
                autoreleasepool { () -> Void in
                    
                    if let sampleBuffer = audioReaderOutput.copyNextSampleBuffer(), let bufferSamples = self.extractSamples(sampleBuffer) {
                        
                        if let audioStreamBasicDescription = CMSampleBufferGetFormatDescription(sampleBuffer)?.audioStreamBasicDescription {
                            
                            let channelCount = Int(audioStreamBasicDescription.mChannelsPerFrame)
                            
                            if bufferSize == 0 {
                                bufferSize = bufferSamples.count / channelCount
                                sampleRate = Int(audioStreamBasicDescription.mSampleRate)
                            }
                            
                                // only read 1 channel of samples. 
                            for elem in stride(from:0, to: bufferSamples.count - (channelCount-1), by: channelCount)
                            {
                                audioSamples.append(bufferSamples[elem])
                            }
                        }
                        
                        
                    }
                    else {
                        audioReader.cancelReading()
                    }
                }
            }
        }
        
        audioSamples.reverse()
        
        return (bufferSize, sampleRate, audioSamples)
    }
    
    func sampleBufferForSamples(audioSamples:[Int16], sampleRate:Int) -> CMSampleBuffer? {
        
        var sampleBuffer:CMSampleBuffer?
        
        let bytesInt16 = MemoryLayout<Int16>.stride
        let dataSize = audioSamples.count * bytesInt16
        
        var samplesBlock:CMBlockBuffer? 
        
        let memoryBlock:UnsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(
            byteCount: dataSize,
            alignment: MemoryLayout<Int16>.alignment)
        
        let _ = audioSamples.withUnsafeBufferPointer { buffer in
            memoryBlock.initializeMemory(as: Int16.self, from: buffer.baseAddress!, count: buffer.count)
        }
        
        if CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault, 
            memoryBlock: memoryBlock, 
            blockLength: dataSize, 
            blockAllocator: nil, 
            customBlockSource: nil, 
            offsetToData: 0, 
            dataLength: dataSize, 
            flags: 0, 
            blockBufferOut:&samplesBlock
        ) == kCMBlockBufferNoErr, let samplesBlock = samplesBlock {
            
            var asbd = AudioStreamBasicDescription()
            asbd.mSampleRate = Float64(sampleRate)
            asbd.mFormatID = kAudioFormatLinearPCM
            asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
            asbd.mBitsPerChannel = 16
            asbd.mChannelsPerFrame = 1
            asbd.mFramesPerPacket = 1
            asbd.mBytesPerFrame = 2
            asbd.mBytesPerPacket = 2
            
            var formatDesc: CMAudioFormatDescription?
            
            if CMAudioFormatDescriptionCreate(allocator: nil, asbd: &asbd, layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil, formatDescriptionOut: &formatDesc) == noErr, let formatDesc = formatDesc {
                
                if CMSampleBufferCreate(allocator: kCFAllocatorDefault, dataBuffer: samplesBlock, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: formatDesc, sampleCount: audioSamples.count, sampleTimingEntryCount: 0, sampleTimingArray: nil, sampleSizeEntryCount: 0, sampleSizeArray: nil, sampleBufferOut: &sampleBuffer) == noErr, let sampleBuffer = sampleBuffer {
                    
                    guard sampleBuffer.isValid, sampleBuffer.numSamples == audioSamples.count else {
                        return nil
                    }
                }
            }
        }
        
        return sampleBuffer
    }
    
    func sampleBuffersForSamples(bufferSize:Int, audioSamples:[Int16], sampleRate:Int) -> [CMSampleBuffer?] {
        
        let blockedAudioSamples = audioSamples.blocks(size: bufferSize)
        
        let sampleBuffers = blockedAudioSamples.map { audioSamples in
            sampleBufferForSamples(audioSamples: audioSamples, sampleRate: sampleRate)
        }
        
        return sampleBuffers
    }
    
    func saveSampleBuffersToFile(_ sampleBuffers:[CMSampleBuffer?], destinationURL:URL, progress: @escaping (Float) -> (), completion: @escaping (Bool, String?) -> ())  {
        
        let nbrSamples = sampleBuffers.count
        
        guard nbrSamples > 0, let firstSampleBuffer = sampleBuffers.first, let sampleBuffer = firstSampleBuffer  else {
            completion(false, "Invalid buffer list.")
            return
        }
        
        do {
            try FileManager.default.removeItem(at: destinationURL)
        } catch _ {}
        
        guard let assetWriter = try? AVAssetWriter(outputURL: destinationURL, fileType: AVFileType.wav) else {
            completion(false, "Can't create asset writer.")
            return
        }
        
        let sourceFormat = CMSampleBufferGetFormatDescription(sampleBuffer)
        
        let audioFormatSettings = [AVFormatIDKey: kAudioFormatLinearPCM] as [String : Any]
        
        if assetWriter.canApply(outputSettings: audioFormatSettings, forMediaType: AVMediaType.audio) == false {
            completion(false, "Can't apply output settings to asset writer.")
            return
        }
        
        let audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings:audioFormatSettings, sourceFormatHint: sourceFormat)
        
        audioWriterInput.expectsMediaDataInRealTime = kAudioWriterExpectsMediaDataInRealTime
        
        if assetWriter.canAdd(audioWriterInput) {
            assetWriter.add(audioWriterInput)
            
        } else {
            completion(false, "Can't add audio input to asset writer.")
            return
        }
        
        let serialQueue: DispatchQueue = DispatchQueue(label: kReverseAudioQueue)
        
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: CMTime.zero)
        
        var index = 0
        
        func finishWriting() {
            assetWriter.finishWriting {
                switch assetWriter.status {
                    case .failed:
                        
                        var errorMessage = ""
                        if let error = assetWriter.error {
                            
                            let nserr = error as NSError
                            
                            let description = nserr.localizedDescription
                            errorMessage = description
                            
                            if let failureReason = nserr.localizedFailureReason {
                                print("error = \(failureReason)")
                                errorMessage += ("Reason " + failureReason)
                            }
                        }
                        completion(false, errorMessage)
                        print("errorMessage = \(errorMessage)")
                        return
                    case .completed:
                        print("completed")
                        completion(true, nil)
                        return
                    default:
                        print("failure")
                        completion(false, nil)
                        return
                }
            }
        }
        
        audioWriterInput.requestMediaDataWhenReady(on: serialQueue) {
            
            while audioWriterInput.isReadyForMoreMediaData, index < nbrSamples {
                
                if let currentSampleBuffer = sampleBuffers[index] {
                    audioWriterInput.append(currentSampleBuffer)
                }
                
                index += 1
                
                progress(Float(index) / Float(nbrSamples))
                
                if index == nbrSamples {
                    audioWriterInput.markAsFinished()
                    
                    finishWriting()
                }
            }
        }
    }
    
    func reverseAudio(asset:AVAsset, destinationURL:URL, progress: @escaping (Float) -> (), completion: @escaping (Bool, String?) -> ())  {
        
        guard let (bufferSize, sampleRate, audioSamples) = readAndReverseAudioSamples(asset: asset) else {
            completion(false, "Can't read audio samples")
            return
        }
        
        let sampleBuffers = sampleBuffersForSamples(bufferSize: bufferSize, audioSamples: audioSamples, sampleRate: sampleRate)
        
        saveSampleBuffersToFile(sampleBuffers, destinationURL: destinationURL, progress: progress, completion: completion)
    }
    
}
