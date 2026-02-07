//
//  SystemCoordinator.swift
//  SceneReconstruction
//
//  Main coordinator that integrates all components of the architecture
//

import Foundation
import RealityKit
import CoreImage
import Vision
import Metal
import SwiftUI

@main
struct SceneReconstructionApp: SwiftUI.App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            VStack {
                Text("Scene Reconstruction")
                    .font(.largeTitle)
                Text("Phase 1 Foundation")
                    .font(.subheadline)
            }
        }
    }
}

/// Coordinates between all system components for complete scene reconstruction pipeline
class SystemCoordinator {
    
    // MARK: - Properties
    
    private let objectCapturePipeline: ObjectCapturePipeline
    private let objectCaptureManager: ObjectCaptureManager
    private let lightingAnalyzer: LightingAnalyzer
    private let pbrRenderer: PBRRenderer?
    
    // Completion handler for the full reconstruction process
    typealias ReconstructionCompletion = (RKEntity?, Error?) -> Void
    
    // MARK: - Initialization
    
    init() {
        objectCapturePipeline = ObjectCapturePipeline()
        objectCaptureManager = ObjectCaptureManager(pipeline: objectCapturePipeline)
        
        // Setup lighting analyzer with Core Image context from pipeline
        let metalDevice = MTLCreateSystemDefaultDevice()
        guard let device = metalDevice else {
            print("Failed to create Metal device")
            
            // Create CIContext without Metal for fallback (Phase 1 requirement)  
            let ciContext = CIContext() 
            lightingAnalyzer = LightingAnalyzer(ciContext: ciContext)
            
            pbrRenderer = nil
            return   
        }
        
        let ciContext = CIContext(mtlDevice: device)
        lightingAnalyzer = LightingAnalyzer(ciContext: ciContext)
        
        // Setup PBR renderer if Metal device is available  
        pbrRenderer = PBRRenderer(metalDevice: device) 
    } 
    
    // MARK: - Public Methods
    
    /// Perform complete scene reconstruction from input images and RAW data
    @MainActor
    func reconstructScene(from captureImages: [UIImage],
                          rawImageData: Data,
                          completion: @escaping ReconstructionCompletion) {
        let completion = completion
        
        Task { @MainActor in
            do {
                let result = try await performReconstruction(captureImages, rawImageData)
                completion(result.entity, nil)
                
            } catch {
                completion(nil, error)
            }
        }
    }
    
    /// Perform complete scene reconstruction and return the results
    func reconstructScene(from captureImages: [UIImage],
                          rawImage: CIImage) async throws -> (entity: RKEntity?, lighting: LightingAnalysis?) {
        
        // Step 1: Capture object using RealityKit ObjectCapture
        print("Step 1: Capturing object with RealityKit...")
        let capturedEntity = try await objectCaptureManager.startCapture(with: captureImages)
        
        guard var entity = capturedEntity else {
            throw SceneReconstructionError.objectCaptureFailed
        }
        
        // Step 2: Analyze lighting conditions from RAW image
        print("Step 2: Analyzing lighting conditions...")
        let lightingAnalysis = await lightingAnalyzer.analyzeLighting(from: rawImage)
        
        guard let analysis = lightingAnalysis else {
            throw SceneReconstructionError.lightingAnalysisFailed
        }
        
        // Step 3: Apply PBR materials to the captured entity
        print("Step 3: Applying PBR materials...")
        if let renderer = pbrRenderer {
            let config = PBRRenderer.PBRLightingConfig(
                intensity: analysis.brightness,
                colorTemperature: analysis.colorTemperature
            )
            
            _ = renderer.applyPBRMaterial(to: &entity, with: config)
            
            // Update any material properties based on analysis results
            // In a real implementation this would be more comprehensive
            
            print("Scene reconstruction completed successfully")
        } else {
            print("Warning: PBR rendering not available - using default materials")
        }
        
        return (entity, analysis)
    }
    
    /// Private async method that performs the actual reconstruction steps
    private func performReconstruction(_ captureImages: [UIImage], _ rawImageData: Data) async throws -> (entity: RKEntity?, lighting: LightingAnalysis?) {
        
        // Convert RAW data to CIImage for processing
        guard let ciImage = convertToCIImage(rawImageData) else {
            throw SceneReconstructionError.invalidRawData
        }
        
        return try await reconstructScene(from: captureImages, rawImage: ciImage)
    }
    
    /// Convert RAW image data to CIImage for analysis
    private func convertToCIImage(_ rawData: Data) -> CIImage? {
        // Phase 1 implementation: Attempt to create CIImage from raw data
        
        // Try creating CIImage directly from the data (works for some formats like PNG/JPEG)
        guard let ciImage = CIImage(data: rawData) else {
            print("Warning: Could not create CIImage directly from RAW data")
            
            // For true RAW formats (like DNG), we would need additional processing
            // This is a placeholder implementation that demonstrates the integration pattern
            
            return nil  // Return nil for unsupported/invalid RAW data in Phase 1
        }
        
        print("Successfully created CIImage from input data")
        return ciImage
    }
}

// MARK: - Error Handling

enum SceneReconstructionError: Error {
    case objectCaptureFailed
    case lightingAnalysisFailed
    case invalidRawData
    case pbrRenderingFailed
    
    var localizedDescription: String {
        switch self {
        case .objectCaptureFailed:
            return "Object capture failed to produce a valid entity"
        case .lightingAnalysisFailed:
            return "Lighting analysis could not determine conditions from RAW image data"
        case .invalidRawData:
            return "Provided RAW image data is invalid or unsupported format"
        case .pbrRenderingFailed:
            return "PBR rendering failed during material application"
        }
    }
}

