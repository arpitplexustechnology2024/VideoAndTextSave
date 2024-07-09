//
//  ThumbnailsViewController.swift
//  VideoAndTextSave
//
//  Created by Arpit iOS Dev. on 09/07/24.
//

import UIKit
import AVFoundation

class ThumbnailsViewController: UIViewController {

    let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(thumbnailImageView)
        NSLayoutConstraint.activate([
            thumbnailImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            thumbnailImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 450),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 700)
        ])
        
        guard let videoURL = Bundle.main.url(forResource: "video3", withExtension: "mp4") else {
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
}
