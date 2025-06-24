//
//  ViewController.swift
//  Gridify
//
//  Created by Jim Wu on 2025/6/12.
//

import UIKit
import PhotosUI

class ViewController: UIViewController {
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var loadingIndicator: UILabel!
    @IBOutlet var infoButton: UIButton!
    @IBOutlet var appTitle: UILabel!
    
    @IBOutlet var button4x4: UIButton!
    @IBOutlet var button4x6: UIButton!
    @IBOutlet var button4x8: UIButton!
    @IBOutlet var button4x10: UIButton!
    
    @IBOutlet var button6x8: UIButton!
    @IBOutlet var button6x10: UIButton!
    @IBOutlet var button6x12: UIButton!
    
    @IBOutlet var button8x10: UIButton!
    @IBOutlet var button8x12: UIButton!
    
    private var selectedImages: [UIImage] = []
    private var gridRows = 12
    private var gridCols = 8
    
    private var finalImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
        loadingIndicator.isHidden = true
    }
    
    private func setLoading(_ isLoading: Bool) {
        activityIndicator.isHidden = !isLoading
        loadingIndicator.isHidden = !isLoading
        
        button4x4.isHidden = isLoading
        button4x6.isHidden = isLoading
        button4x8.isHidden = isLoading
        button4x10.isHidden = isLoading
        
        button6x8.isHidden = isLoading
        button6x10.isHidden = isLoading
        button6x12.isHidden = isLoading
        
        button8x10.isHidden = isLoading
        button8x12.isHidden = isLoading
        
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    @IBAction func gridFormatButtonTapped(_ sender: UIButton) {
        switch sender {
        case button4x4:
            gridCols = 4
            gridRows = 4
        case button4x6:
            gridCols = 4
            gridRows = 6
        case button4x8:
            gridCols = 4
            gridRows = 8
        case button4x10:
            gridCols = 4
            gridRows = 10
        case button6x8:
            gridCols = 6
            gridRows = 8
        case button6x10:
            gridCols = 6
            gridRows = 10
        case button6x12:
            gridCols = 6
            gridRows = 12
        case button8x10:
            gridCols = 8
            gridRows = 10
        case button8x12:
            gridCols = 8
            gridRows = 12
        default:
            return
        }
        
        presentPhotoPicker()
    }
    
    
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = gridCols * gridRows
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func generateGridImage(from images: [UIImage], completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard images.count == self.gridRows * self.gridCols else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let totalSize = CGSize(width: 1200, height: 2000)
            let cellWidth = totalSize.width / CGFloat(self.gridCols)
            let cellHeight = totalSize.height / CGFloat(self.gridRows)
            let cellSize = CGSize(width: cellWidth, height: cellHeight)
            
            UIGraphicsBeginImageContextWithOptions(totalSize, false, 3.0)
            guard let context = UIGraphicsGetCurrentContext() else {
                UIGraphicsEndImageContext()
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            for row in 0..<self.gridRows {
                for col in 0..<self.gridCols {
                    let index = row * self.gridCols + col
                    let image = images[index]
                    let targetRect = CGRect(x: CGFloat(col) * cellSize.width,
                                            y: CGFloat(row) * cellSize.height,
                                            width: cellSize.width,
                                            height: cellSize.height)
                    
                    context.saveGState()
                    context.clip(to: targetRect)
                    
                    let imageSize = image.size
                    let imageAspect = imageSize.width / imageSize.height
                    let cellAspect = cellSize.width / cellSize.height
                    
                    var drawSize = CGSize.zero
                    if imageAspect > cellAspect {
                        drawSize.height = cellSize.height
                        drawSize.width = cellSize.height * imageAspect
                    } else {
                        drawSize.width = cellSize.width
                        drawSize.height = cellSize.width / imageAspect
                    }
                    
                    let originX = targetRect.origin.x - (drawSize.width - cellSize.width) / 2.0
                    let originY = targetRect.origin.y - (drawSize.height - cellSize.height) / 2.0
                    let drawRect = CGRect(origin: CGPoint(x: originX, y: originY), size: drawSize)
                    
                    image.draw(in: drawRect)
                    context.restoreGState()
                }
            }
            
            let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            DispatchQueue.main.async {
                completion(combinedImage)
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto",
           let photoVC = segue.destination as? PhotoViewController {
            photoVC.image = self.finalImage
        }
    }
    
}
extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        if results.isEmpty {
            return
        }
        
        selectedImages = Array(repeating: UIImage(), count: results.count)
        
        let group = DispatchGroup()
        activityIndicator.startAnimating()
        
        for (index, result) in results.enumerated() {
            let item = result.itemProvider
            group.enter()
            item.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    self.selectedImages[index] = image
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.setLoading(false)
            let expectedCount = self.gridCols * self.gridRows
            
            if self.selectedImages.contains(where: { $0.size == .zero}) {
                let alert = UIAlertController(title: "Error", message: "Some photos failed to load.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            
            if self.selectedImages.count == expectedCount {
                self.setLoading(true)
                self.generateGridImage(from: self.selectedImages) { gridImage in
                    self.setLoading(false)
                    if let finalImage = gridImage {
                        self.finalImage = finalImage
                        self.performSegue(withIdentifier: "showPhoto", sender: nil)
                    }
                }
            } else {
                let alert = UIAlertController(title: "Alert!", message: "Please choose \(expectedCount) photos", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }

    }
}
