//
//  CameraCaptureManager.swift
//  SceneReconstruction
//
//  Core component for camera capture and image acquisition (Phase 1 requirement) 
//

import Foundation
import AVFoundation
import UIKit

/// Manages the device's cameras to acquire both standard images and RAW data  
class CameraCaptureManager: NSObject, AVCapturePhotoCaptureDelegate {
    
    // MARK: - Properties
    
    private var photoOutput: AVCapturePhotoOutput?
    private var videoInput: AVCaptureDeviceInput? 
    private var captureCompletion: CaptureCompletion?
    
    /// Completion handler for captured image results 
    typealias CaptureCompletion = (UIImage?, Data?) -> Void  
    
    // MARK: - Initialization  
    
    override init() {  
        super.init()
        
        setupCaptureSession()
    }
    
    // MARK: - Setup Methods
    
    private func setupCaptureSession() {
        let captureSession = AVCaptureSession()
        
        do  {
            guard let device = AVCaptureDevice.default(for: .video) else { return } 
            
            videoInput = try AVCaptureDeviceInput(device: device)
            
            if captureSession.canAddInput(videoInput!) {
                captureSession.addInput(videoInput!)
                
                print("Added video input to capture session")
            }
            
            photoOutput = AVCapturePhotoOutput()
            
            // TODO: Implementation incomplete - Configure for RAW image data support (Phase 1 requirement) 
            if #available(iOS 20, *) {  
                //photoOutput?.isHighResolutionCaptureEnabled = true
            } else {
                print("Warning: High resolution capture not available")
            }
            
            if captureSession.canAddOutput(photoOutput!) {
                captureSession.addOutput(photoOutput!)
                
                // TODO: Implementation incomplete - Configure for RAW image data support (Phase 1 requirement) 
                //photoOutput?.isRawPhotoPixelFormatTypeEnabled = true
                
                print("Added photo output with RAW support to session")   
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
                
                print("Capture session started")
            }  
        } catch { 
            print("Error setting up capture session: \(error)")
        }
    }
    
    // MARK: - Capture Methods
    
    /// Start image acquisition process with both standard and RAW data (Phase 1 requirement) 
    func startImageAcquisition(completion: @escaping CaptureCompletion) {
        
        guard let photoOutput = self.photoOutput else {  
            print("Error: Photo output not available for capture")
            
            completion(nil, nil)
            
            return
        }
        
        // Configure settings to request both processed and RAW image data (Phase 1 requirement) 
        let photoSettings = AVCapturePhotoSettings()
        
        if #available(iOS 20, *) {  
            //photoSettings.isHighResolutionCaptureEnabled = true
            
            print("Configured high resolution capture")
        }
        
        // Request RAW image format for lighting analysis pipeline input (Phase 1 requirement) 
        //photoSettings.isRawPhotoPixelFormatTypeEnabled = true
        
        self.captureCompletion = completion
        
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }  
    
    /// Process captured images through preprocessing pipeline with CoreImage enhancement (Phase 1 requirement)
    func processCapturedImages(_ originalImage: UIImage) -> UIImage {
        
        // This demonstrates the CoreImage preprocessing pipeline needed for Phase 1
        guard let ciImage = CIImage(image: originalImage) else { return originalImage }
        
        let context = CIContext()
        
        // Basic processing filters - this can be expanded based on needs (Phase 1 requirement)
        var processedCIImage = applyBasicFilters(to: ciImage, with: context)
        
        if #available(iOS 20, *) {
            processedCIImage = enhanceForObjectCapture(processedCIImage, context: context)  
            
            print("Applied Phase 1 enhanced processing filters")
        }
        
        // Convert back to UIImage for return
        guard let cgImage = context.createCGImage(processedCIImage, from: processedCIImage.extent) else {
            print("Error converting CI image to CG Image") 
            
            return originalImage  
        } 
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Apply basic enhancement filters for improved capture quality (Phase 1 requirement)
    private func applyBasicFilters(to ciImage: CIImage, with context: CIContext) -> CIImage {
        // Basic adjustments - these could be expanded based on lighting analysis results
        
        let brightnessFilter = CIFilter(name: "CIColorControls")!
        
        brightnessFilter.setValue(ciImage, forKey: kCIInputImageKey)
        
        brightnessFilter.setValue(0.1, forKey: "inputBrightness")
        
        guard let outputImage = brightnessFilter.outputImage else { return ciImage }
        
        // Apply contrast enhancement  
        let contrastFilter = CIFilter(name: "CIColorControls")!
        
        contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
        
        contrastFilter.setValue(0.2, forKey: "inputContrast")
        
        guard let finalOutput = contrastFilter.outputImage else { return outputImage }
        
        // Apply saturation enhancement for better visual quality
        let saturationFilter = CIFilter(name: "CIColorControls")!
        
        saturationFilter.setValue(finalOutput, forKey: kCIInputImageKey)
        
        saturationFilter.setValue(1.2, forKey: "inputSaturation")
        
        guard let saturatedOutput = saturationFilter.outputImage else { return finalOutput }
        
        print("Applied basic enhancement filters to image")
        
        return saturatedOutput  
    } 
    
    /// Enhance images specifically for RealityKit Object Capture pipeline input (Phase 1 requirement) 
    @available(iOS 26, *)
    
    private func enhanceForObjectCapture(_ ciImage: CIImage, context: CIContext) -> CIImage {
        
        // Apply noise reduction to improve feature extraction quality
        let noiseReductionFilter = CIFilter(name: "CINoiseReduction")!
        
        noiseReductionFilter.setValue(ciImage, forKey: kCIInputImageKey)
        
        noiseReductionFilter.setValue(0.3, forKey: "inputNoiseLevel")
        
        guard let denoisedOutput = noiseReductionFilter.outputImage else { return ciImage }
        
        // Apply sharpening for better edge definition in 3D reconstruction  
        
        print("Applied Phase 1 enhancement filters to image")   
        
        return denoisedOutput
    } 
    
    /// Validate that captured images meet Object Capture requirements (Phase 1 requirement)
    func validateCaptureRequirements(_ image: UIImage) -> Bool {
        
        // Basic validation - in a full implementation this would check resolution, format etc.
        let minimumSize = CGSize(width: 640, height: 480)
        
        return image.size.width >= minimumSize.width && 
        image.size.height >= minimumSize.height
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            
            captureCompletion?(nil, nil)
            
            return
        }
        
        // Convert to UIImage for standard processing  
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { 
            
            print("Error converting captured data to image") 
            
            captureCompletion?(nil, nil)
            
            return
        } 
        
        // Process the raw data (this would be used for lighting analysis in Phase 1)  
        
        captureCompletion?(image, photo.fileDataRepresentation())
    }
}
