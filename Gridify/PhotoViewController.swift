//
//  PhotoViewController.swift
//  Gridify
//
//  Created by Jim Wu on 2025/6/12.
//

import UIKit

class PhotoViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var saveButton: UIButton!
    
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        imageView.image = image
    }
    
    private func setupUI() {
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
    }
    
    @IBAction func saveImage(_ sender: UIButton) {
        guard let imageToSave = image else { return }
        UIImageWriteToSavedPhotosAlbum(imageToSave, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let alert = UIAlertController(
            title: nil,
            message: error == nil ? "Image saved！" : "Error",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            if error == nil {
                self.dismiss(animated: true)
            }
        })
        present(alert, animated: true)
    }
}
