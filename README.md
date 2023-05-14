
![ReverseAudio](https://www.limit-point.com/assets/images/ReverseAudio.jpg)
# ReverseAudio.swift
## Reverses one channel of an audio file into another 1-channel WAV audio file

Learn more about reversing audio files from our [in-depth blog post](https://www.limit-point.com/blog/2022/reverse-audio).

The associated Xcode project implements a [SwiftUI] app for macOS and iOS that presents a list of audio files included in the bundle resources subdirectory 'Audio Files'.

Add your own audio files or use the sample set provided. 

Each file in the list has an adjacent button to either play or reverse the audio.

## Classes

The project is comprised of:

1. The [App] (`ReverseAudioApp`) that displays a list of audio files in the project.
2. And an [ObservableObject] (`ReverseAudioObservable`) that manages the user interaction to reverse and play audio files in the list.
3. The [AVFoundation] code (`ReverseAudio`) that reads, reverses and writes audio files.

### ReverseAudio

Reversing audio is performed in 3 steps using [AVFoundation]:

1. Read the audio samples of a file into an `Array` of `[Int16]` and reverse it
2. Create an array of sample buffers [[CMSampleBuffer]] for the array of reversed audio samples
3. Write the reversed sample buffers in [[CMSampleBuffer]] to a file

The top level method that implements all of this, and is employed by the `ReverseAudioObservable` is: 

```swift
func reverseAudio(asset:AVAsset, destinationURL:URL, progress: @escaping (Float) -> (), completion: @escaping (Bool, String?) -> ())
```

[App]: https://developer.apple.com/documentation/swiftui/app
[ObservableObject]: https://developer.apple.com/documentation/combine/observableobject
[AVFoundation]: https://developer.apple.com/documentation/avfoundation/
[SwiftUI]: https://developer.apple.com/tutorials/swiftui
[CMSampleBuffer]: https://developer.apple.com/documentation/coremedia/cmsamplebuffer
