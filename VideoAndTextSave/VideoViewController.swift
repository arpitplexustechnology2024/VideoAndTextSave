//
//  VideoViewController.swift
//  VideoAndTextSave
//
//  Created by Arpit iOS Dev. on 08/07/24.
//

import UIKit
import AVFoundation
import Photos

class VideoViewController: UIViewController {

    var player: AVPlayer?
    var playerLayer: AVPlayerLayer!
    var exportButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load and play the video
        if let videoURL = Bundle.main.url(forResource: "SodaRecipe", withExtension: "mp4") {
            player = AVPlayer(url: videoURL)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.frame = view.bounds
            view.layer.addSublayer(playerLayer)

            // Overlay text on video
            addTextOverlay()

            player?.play()
        } else {
            print("Video file not found")
        }


        // Create UIButton
        exportButton = UIButton(type: .system)
        exportButton.setTitle("Export Video", for: .normal)
        exportButton.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)
        exportButton.frame = CGRect(x: 20, y: 750, width: view.bounds.width - 40, height: 50)
        exportButton.backgroundColor = .blue
        exportButton.setTitleColor(.white, for: .normal)
        view.addSubview(exportButton)
    }

    @objc func exportButtonTapped() {
        exportVideoToPhotos()
    }

    func exportVideoToPhotos() {
        guard let videoURL = Bundle.main.url(forResource: "SodaRecipe", withExtension: "mp4") else {
            print("Video file not found")
            return
        }

        let asset = AVURLAsset(url: videoURL)
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            print("Video track not found")
            return
        }

        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            print("Failed to create composition track")
            return
        }

        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
        } catch {
            print("Failed to insert time range: \(error)")
            return
        }

        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = generateExportURL()
        exporter?.outputFileType = .mp4
        exporter?.shouldOptimizeForNetworkUse = true

        guard let exportSession = exporter else {
            print("Failed to create export session")
            return
        }

        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    self.saveVideoToPhotos(url: exportSession.outputURL!)
                case .failed:
                    print("Export failed: \(String(describing: exportSession.error))")
                case .cancelled:
                    print("Export cancelled")
                default:
                    break
                }
            }
        }
    }

    func saveVideoToPhotos(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photo library access not authorized")
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { saved, error in
                DispatchQueue.main.async {
                    if saved {
                        print("Video saved to Photos")
                    } else {
                        print("Error saving video: \(String(describing: error))")
                    }
                }
            }
        }
    }

    func generateExportURL() -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let exportFileName = "SodaRecipe_\(dateFormatter.string(from: Date())).mp4"
        let exportURL = documentsDirectory?.appendingPathComponent(exportFileName)
        return exportURL
    }

    func addTextOverlay() {
        // Create text layer
        let textLayer = CATextLayer()
        textLayer.string = "Soda Recipe Video"
        textLayer.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        textLayer.fontSize = 36
        textLayer.alignmentMode = .center
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.frame = CGRect(x: 25, y: 100, width: playerLayer.frame.width - 40, height: 100)

        // Add text layer to player layer's super layer
        playerLayer.addSublayer(textLayer)
    }
}
