//
//  VideoViewController.swift
//  VideoAndTextSave
//
//  Created by Arpit iOS Dev. on 08/07/24.
//

import UIKit
import AVFoundation
import AVKit
import Photos

class VideoViewController: UIViewController {
    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var overlayTextLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        guard let videoURL = Bundle.main.url(forResource: "SodaRecipe", withExtension: "mp4") else { return }
        player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
        
        overlayTextLabel = UILabel()
        overlayTextLabel.text = "Soda Recipe Video"
        overlayTextLabel.textColor = .white
        overlayTextLabel.font = UIFont.boldSystemFont(ofSize: 24)
        overlayTextLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayTextLabel)
        
        NSLayoutConstraint.activate([
            overlayTextLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlayTextLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50)
        ])
        
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save Video", for: .normal)
        saveButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
        saveButton.addTarget(self, action: #selector(saveVideo), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }
    
    @objc func saveVideo() {
        exportVideoWithOverlay { [weak self] exportedURL in
            guard let self = self else { return }
            self.saveToPhotos(url: exportedURL)
        }
    }
    
    func exportVideoWithOverlay(completion: @escaping (URL) -> Void) {
        guard let videoURL = Bundle.main.url(forResource: "SodaRecipe", withExtension: "mp4") else { return }
        let composition = AVMutableComposition()
        
        let asset = AVAsset(url: videoURL)
        guard let videoTrack = asset.tracks(withMediaType: .video).first else { return }
        let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
        
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(x: 0, y: 50, width: UIScreen.main.bounds.width, height: 100)
        let textLayer = CATextLayer()
        textLayer.string = "Soda Recipe Video"
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.font = UIFont.boldSystemFont(ofSize: 24) as CFTypeRef
        textLayer.fontSize = 24
        textLayer.alignmentMode = .center
        textLayer.frame = overlayLayer.bounds
        overlayLayer.addSublayer(textLayer)
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(overlayLayer)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: outputLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("exportedVideo.mp4")
        exporter.outputURL = exportURL
        exporter.outputFileType = .mp4
        exporter.videoComposition = videoComposition
        
        exporter.exportAsynchronously {
            if exporter.status == .completed {
                DispatchQueue.main.async {
                    completion(exportURL)
                }
            } else {
                print("Export failed with error: \(exporter.error?.localizedDescription ?? "")")
            }
        }
    }
    
    func saveToPhotos(url: URL) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { saved, error in
            if saved {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Saved!", message: "Your video with text overlay has been saved to your Photos.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            } else {
                if let error = error {
                    print("Failed to save video to Photos: \(error.localizedDescription)")
                } else {
                    print("Failed to save video to Photos for an unknown reason.")
                }
            }
        }
    }
}
