//
//  ViewController.swift
//  EmotionDetector
//
//  Created by achim on 18/05/2024.
//

import UIKit
import CoreML

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "photo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let label : UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Select Image"
        label.numberOfLines = 0
        return label
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.addSubview(label)
        view.addSubview(imageView)
        
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapImage)
        )
        tap.numberOfTapsRequired = 1
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tap)
    }
    
    @objc func didTapImage() {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            present(picker, animated: true)
        }
    
    override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            imageView.frame = CGRect(
                x: 20,
                y: view.safeAreaInsets.top,
                width: view.frame.size.width-40,
                height: view.frame.size.width-40)
            label.frame = CGRect(
                x: 20,
                y: view.safeAreaInsets.top+(view.frame.size.width-40)+10,
                width: view.frame.size.width-40,
                height: 100
            )
        }
    
    private func analyzeImage(image: UIImage?){
        guard let buffer = image?.resize(size: CGSize(width: 224, height: 224))?
            .getCVPixelBuffer() else{
            return
        }
                

        do{
            let config = MLModelConfiguration()
            print(config)
            let model = try NewModel(configuration: config)
            let resized = image?.resize(size: CGSize(width: 224, height: 224))
            let input = NewModelInput(input_1: (resized?.mlMultiArray())!)
            let output = try model.prediction(input: input)
            let predictions = output.featureValue(for: "Identity")?.multiArrayValue
            var max : Double = 0
            var indexOfMax = 0
            
            for i in 0...6
            {
                if(predictions![i].doubleValue > max)
                {
                    indexOfMax = i
                    max = predictions![i].doubleValue
                }
                print(i)
                print(predictions![i].doubleValue)
            }
            
            switch indexOfMax{
            case 0: 
                label.text = "angry"
            case 1: 
                label.text = "disgust"
            case 2: 
                label.text = "fear"
            case 3: 
                label.text = "happy"
            case 4: 
                label.text = "neutral"
            case 5: 
                label.text = "sad"
            case 6: 
                label.text = "surprise"
            default:
                label.text = "neutral"
            }
            
        }
        catch{
            print(error.localizedDescription)
        }
    }

    // Image Picker

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // cancelled
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        imageView.image = image
        analyzeImage(image: image)
    }
}


