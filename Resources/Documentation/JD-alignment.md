# Job Description Alignment & Correlation

This document correlates the requirements outlined in `JD.docx` with the current project architecture, implementation status, and roadmap.

## 1. Core Technology Alignment

| JD Requirement | Project Component | Status | Correlation Notes |
| :--- | :--- | :--- | :--- |
| **Object Capture** | `ObjectCaptureManager.swift` | ⚠️ Partial | The architecture identifies RealityKit Object Capture as the primary engine, but implementation is currently in the placeholder stage. |
| **LiDAR / Depth Sensing** | Sensor Fusion Module | ⏳ Phase 2 | Required for "3D sensing capability." Current focus is on RGB; depth integration is a major roadmap gap. |
| **RAW Camera Data** | `ImagePreprocessingPipeline` | ✅ Implemented | Alignment on "going deep on software-to-hardware interface" via CoreImage and RAW histogram analysis. |
| **Vision Framework** | `VisionFeatureExtractor.swift` | ✅ Implemented | Used for keypoint detection and feature descriptors as requested. |
| **Metal** | `MetalShaderManager.swift` | ⚠️ Structural | Metal is integrated for PBR and enhancement, but performance optimization (a JD focus) is still pending. |
| **Documentation** | `Resources/Documentation/` | ✅ Strong | JD requires Markdown proficiency; project maintains a comprehensive set of architectural MD files. |

## 2. Strategic Correlation

### The "Rebuild" Approach
The JD notes that while this is a port from Android, it is "really a rebuild" due to hardware differences. The project architecture reflects this by leveraging Apple-specific technologies (RealityKit, Metal, Apple Neural Engine) rather than generic cross-platform wrappers.

### Analysis vs. Synthesis
The JD emphasizes **computer vision (analysis)** over computer graphics (synthesis). The architecture prioritizes Layers 1-3 (Acquisition, Feature Extraction, and Geometry Estimation), which aligns with the JD's focus on capturing scene geometry and light detail.

### Optimization Focus
The JD requires "On-Site testing and optimization." The current technical debt list in `CurrentImplementationStatus.md` specifically identifies the lack of SIMD/vecLib and Metal Performance Shader optimizations as a primary bottleneck for Phase 1.

## 3. Implementation Gaps vs. JD Requirements

To fully satisfy the JD's requirements, the following areas need immediate attention:

1.  **LiDAR & Depth Sensing**: Move from "Phase 2" to "Phase 1" priority to meet the "iPhone depth-sensing camera system" requirement.
2.  **Object Capture Workflow**: Transition `ObjectCaptureManager.swift` from a basic structure to a functional RealityKit session.
3.  **Low-Level Math (SIMD)**: Complete the `GeometryEstimator.swift` implementation using `Accelerate` and `vecLib` to demonstrate the "software-to-hardware" expertise requested.
4.  **Cloud Integration**: Define the "Environment data passed to web services" pipeline, which is currently a secondary focus in the architecture.

---
*Created: Friday, February 6, 2026*
