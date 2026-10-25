// Encodes a Godot Movie Maker PNG sequence (+ its WAV audio) into an App Store preview:
// H.264 video, AAC stereo audio, 30 fps, .mp4. No ffmpeg needed (uses AVFoundation).
// Video and audio are fed side by side (requestMediaDataWhenReady); feeding one track
// completely before the other makes AVAssetWriter stall.
//   swiftc -O tools/encode_preview.swift -o /tmp/encode_preview
//   /tmp/encode_preview <frames_dir> <audio.wav> <out.mp4> [fps]
import AVFoundation
import AppKit

let args = CommandLine.arguments
guard args.count >= 4 else {
    print("usage: encode_preview <frames_dir> <audio.wav> <out.mp4> [fps]"); exit(1)
}
let framesDir = URL(fileURLWithPath: args[1])
let audioURL = URL(fileURLWithPath: args[2])
let outURL = URL(fileURLWithPath: args[3])
let fps = Int32(args.count > 4 ? Int(args[4])! : 30)

let frames = try FileManager.default.contentsOfDirectory(atPath: framesDir.path)
    .filter { $0.hasSuffix(".png") }.sorted()

func loadCG(_ name: String) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(framesDir.appendingPathComponent(name) as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

guard let firstCG = loadCG(frames[0]) else { print("cannot read first frame"); exit(1) }
let width = firstCG.width, height = firstCG.height
try? FileManager.default.removeItem(at: outURL)

let writer = try AVAssetWriter(outputURL: outURL, fileType: .mp4)
let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: width,
    AVVideoHeightKey: height,
    AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: 12_000_000,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
        AVVideoExpectedSourceFrameRateKey: fps,
        AVVideoMaxKeyFrameIntervalKey: fps,
    ],
])
videoInput.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
    kCVPixelBufferWidthKey as String: width,
    kCVPixelBufferHeightKey as String: height,
])
writer.add(videoInput)

let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
    AVFormatIDKey: kAudioFormatMPEG4AAC,
    AVNumberOfChannelsKey: 2,
    AVSampleRateKey: 44100,
    AVEncoderBitRateKey: 256_000,
])
audioInput.expectsMediaDataInRealTime = false
writer.add(audioInput)

let duration = CMTime(value: CMTimeValue(frames.count), timescale: fps)

// Audio reader (trimmed to the video length)
let asset = AVURLAsset(url: audioURL)
let loadSem = DispatchSemaphore(value: 0)
var audioTrack: AVAssetTrack?
asset.loadTracks(withMediaType: .audio) { tracks, _ in audioTrack = tracks?.first; loadSem.signal() }
loadSem.wait()
var audioOut: AVAssetReaderTrackOutput?
var reader: AVAssetReader?
if let track = audioTrack {
    reader = try AVAssetReader(asset: asset)
    reader!.timeRange = CMTimeRange(start: .zero, duration: duration)
    audioOut = AVAssetReaderTrackOutput(track: track, outputSettings: [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsNonInterleaved: false,
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 2,
    ])
    reader!.add(audioOut!)
    reader!.startReading()
} else {
    print("warning: no audio track found")
}

writer.startWriting()
writer.startSession(atSourceTime: .zero)
let group = DispatchGroup()

group.enter()
var frameIndex = 0
videoInput.requestMediaDataWhenReady(on: DispatchQueue(label: "video")) {
    while videoInput.isReadyForMoreMediaData {
        if frameIndex >= frames.count {
            videoInput.markAsFinished(); group.leave(); return
        }
        autoreleasepool {
            guard let cg = loadCG(frames[frameIndex]) else { return }
            var pb: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb)
            guard let buffer = pb else { return }
            CVPixelBufferLockBaseAddress(buffer, [])
            let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
            CVPixelBufferUnlockBaseAddress(buffer, [])
            adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(frameIndex), timescale: fps))
        }
        frameIndex += 1
    }
}

group.enter()
audioInput.requestMediaDataWhenReady(on: DispatchQueue(label: "audio")) {
    while audioInput.isReadyForMoreMediaData {
        if let out = audioOut, let sample = out.copyNextSampleBuffer() {
            audioInput.append(sample)
        } else {
            audioInput.markAsFinished(); group.leave(); return
        }
    }
}

group.wait()
writer.endSession(atSourceTime: duration)
let doneSem = DispatchSemaphore(value: 0)
writer.finishWriting { doneSem.signal() }
doneSem.wait()
if writer.status == .completed {
    print("wrote \(outURL.path) \(width)x\(height) \(frames.count) frames")
} else {
    print("failed: \(String(describing: writer.error))"); exit(1)
}
