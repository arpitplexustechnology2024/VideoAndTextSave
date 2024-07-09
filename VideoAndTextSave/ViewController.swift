//
//  ViewController.swift
//  VideoAndTextSave
//
//  Created by Arpit iOS Dev. on 08/07/24.
//

import UIKit
import Photos

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func saveImageButtonTapped(_ sender: UIButton) {
        guard let image = imageView.image else {
            print("Image not found")
            return
        }
        
        let text = textLabel.text ?? ""
        let imageWithText = drawTextOnImage(image: image, text: text, atPoint: CGPoint(x: 50, y: 50))
        
        saveImageToPhotos(image: imageWithText)
    }
    
    func drawTextOnImage(image: UIImage, text: String, atPoint point: CGPoint) -> UIImage {
        UIGraphicsBeginImageContext(image.size)
        image.draw(at: CGPoint.zero)
        let textColor = UIColor.white
        let textFont = UIFont.boldSystemFont(ofSize: 120)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: textFont
        ]
        text.draw(at: point, withAttributes: attributes)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func saveImageToPhotos(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving image: \(error.localizedDescription)")
        } else {
            print("Image successfully saved to Photos app.")
        }
    }
}
