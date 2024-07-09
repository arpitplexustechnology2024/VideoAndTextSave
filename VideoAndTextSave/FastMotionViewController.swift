//
//  ThumbnailsViewController.swift
//  VideoAndTextSave
//
//  Created by Arpit iOS Dev. on 09/07/24.
//

// MARK: - Fast Motion Video -

import UIKit
import AVFoundation

class FastMotionViewController: UIViewController {

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

        let fastMotionButton = UIButton(type: .system)
        fastMotionButton.setTitle("Play Fast Motion", for: .normal)
        fastMotionButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
        fastMotionButton.frame = CGRect(x: 87, y: view.bounds.height - 60, width: 250, height: 40)
        fastMotionButton.addTarget(self, action: #selector(playFastMotion), for: .touchUpInside)
        view.addSubview(fastMotionButton)

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

    @objc func playFastMotion() {
        createFastMotionVideo()
    }

    func createFastMotionVideo() {
        guard let videoURL = Bundle.main.url(forResource: "SodaRecipe", withExtension: "mp4") else { return }

        let asset = AVURLAsset(url: videoURL)
        let fastMoComposition = AVMutableComposition()

        guard let srcVideoTrack = asset.tracks(withMediaType: .video).first,
              let srcAudioTrack = asset.tracks(withMediaType: .audio).first else { return }

        let fastMoVideoTrack = fastMoComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let fastMoAudioTrack = fastMoComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!

        let assetTimeRange = CMTimeRange(start: .zero, duration: asset.duration)

        try! fastMoVideoTrack.insertTimeRange(assetTimeRange, of: srcVideoTrack, at: .zero)
        try! fastMoAudioTrack.insertTimeRange(assetTimeRange, of: srcAudioTrack, at: .zero)

        let fastMotionMultiplier: Float64 = 0.13 // Adjust for different fast-motion effects
        let newDuration = CMTimeMultiplyByFloat64(assetTimeRange.duration, multiplier: fastMotionMultiplier)
        fastMoVideoTrack.scaleTimeRange(assetTimeRange, toDuration: newDuration)
        fastMoAudioTrack.scaleTimeRange(assetTimeRange, toDuration: newDuration)

        let audioMix = AVMutableAudioMix()
        let audioInputParams = AVMutableAudioMixInputParameters(track: fastMoAudioTrack)
        audioInputParams.audioTimePitchAlgorithm = .varispeed
        audioMix.inputParameters = [audioInputParams]

        let exportSession = AVAssetExportSession(asset: fastMoComposition, presetName: AVAssetExportPresetHighestQuality)!
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("fast-mo-\(Date().timeIntervalSince1970).mp4")
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
