//
//  SlowMotionViewController.swift
//  VideoAndTextSave
//
//  Created by Arpit iOS Dev. on 09/07/24.
//

// MARK: - Slow Motion Video -

import UIKit
import AVFoundation

class SlowMotionViewController: UIViewController {
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let slowMotionButton = UIButton(type: .system)
        slowMotionButton.setTitle("Play Slow Motion", for: .normal)
        slowMotionButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
        slowMotionButton.frame = CGRect(x: 107, y: view.bounds.height - 60, width: 200, height: 40)
        slowMotionButton.addTarget(self, action: #selector(playSlowMotion), for: .touchUpInside)
        view.addSubview(slowMotionButton)
        
        view.addSubview(thumbnailImageView)
        NSLayoutConstraint.activate([
            thumbnailImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            thumbnailImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 600),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 738)
        ])
        
        guard let videoURL = Bundle.main.url(forResource: "SodaRecipe", withExtension: "mp4") else {
            print("Video not found")
            return
        }
        
        let asset = AVAsset(url: videoURL)
        let thumbnail = generateThumbnail(asset: asset, at: CMTime(seconds: 1, preferredTimescale: 600))
        
        if let thumbnail = thumbnail {
            thumbnailImageView.image = thumbnail
        }
        
    }
    
    func generateThumbnail(asset: AVAsset, at time: CMTime) -> UIImage? {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            print("Thumbnail generated successfully")
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    @objc func playSlowMotion() {
        createSlowMotionVideo()
    }
    
    func createSlowMotionVideo() {
        guard let videoURL = Bundle.main.url(forResource: "SodaRecipe", withExtension: "mp4") else { return }
        
        let asset = AVURLAsset(url: videoURL)
        let sloMoComposition = AVMutableComposition()
        
        guard let srcVideoTrack = asset.tracks(withMediaType: .video).first,
              let srcAudioTrack = asset.tracks(withMediaType: .audio).first else { return }
        
        let sloMoVideoTrack = sloMoComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let sloMoAudioTrack = sloMoComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        
        let assetTimeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        try! sloMoVideoTrack.insertTimeRange(assetTimeRange, of: srcVideoTrack, at: .zero)
        try! sloMoAudioTrack.insertTimeRange(assetTimeRange, of: srcAudioTrack, at: .zero)
        
        let slowMotionMultiplier: Float64 = 4.0
        let newDuration = CMTimeMultiplyByFloat64(assetTimeRange.duration, multiplier: slowMotionMultiplier)
        sloMoVideoTrack.scaleTimeRange(assetTimeRange, toDuration: newDuration)
        sloMoAudioTrack.scaleTimeRange(assetTimeRange, toDuration: newDuration)

        let audioMix = AVMutableAudioMix()
        let audioInputParams = AVMutableAudioMixInputParameters(track: sloMoAudioTrack)
        audioInputParams.audioTimePitchAlgorithm = .varispeed
        audioMix.inputParameters = [audioInputParams]
        
        let exportSession = AVAssetExportSession(asset: sloMoComposition, presetName: AVAssetExportPresetHighestQuality)!
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("slow-mo-\(Date().timeIntervalSince1970).mp4")
        exportSession.outputFileType = .mp4
        exportSession.outputURL = outputURL
        exportSession.audioMix = audioMix
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession.status == .completed {
                    self.playVideo(url: outputURL)
                } else {
                    print("Export failed: \(exportSession.error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }
    
    func playVideo(url: URL) {
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.bounds
        view.layer.addSublayer(playerLayer!)
        player?.play()
    }
}
