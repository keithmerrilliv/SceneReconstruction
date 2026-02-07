//
//  ImageEnhancement.metal
//  SceneReconstruction
//
//  Image enhancement shaders for preprocessing captured images
//

#include <metal_stdlib>
using namespace metal;

/// Fragment shader input structure  
struct FragmentInput {
    float4 position [[position]];
    float2 texCoord;
};

/// Vertex shader for full-screen quad rendering (shared across shaders)
vertex FragmentInput fullscreenVertexShader(uint vertexId [[vertex_id]]) {
    FragmentInput out;
    
    // Create a full-screen quad covering the screen
    if (vertexId == 0) {
        out.position = float4(-1.0, -1.0, 0.0, 1.0);
        out.texCoord = float2(0.0, 0.0);
    } else if (vertexId == 1) {
        out.position = float4(3.0, -1.0, 0.0, 1.0);
        out.texCoord = float2(2.0, 0.0);
    } else {
        out.position = float4(-1.0, 3.0, 0.0, 1.0);
        out.texCoord = float2(0.0, 2.0);
    }
    
    return out;
}

/// Simple contrast enhancement shader
fragment float4 contrastEnhancement(FragmentInput in [[stage_in]],
                                     texture2d<float> inputTexture [[texture(0)]],
                                     constant float& contrast [[buffer(1)]]) {
    
    constexpr sampler quadSampler(filter::linear, address::clamp_to_edge);
    float4 color = inputTexture.sample(quadSampler, in.texCoord);
    
    // Apply contrast enhancement
    float3 enhanced = (color.rgb - 0.5) * contrast + 0.5;
    enhanced = clamp(enhanced, 0.0, 1.0);
    
    return float4(enhanced, color.a);
}

/// Brightness and contrast adjustment shader
fragment float4 brightnessContrastEnhancement(FragmentInput in [[stage_in]],
                                               texture2d<float> inputTexture [[texture(0)]],
                                               constant float& brightness [[buffer(1)]],
                                               constant float& contrast [[buffer(2)]]) {
    
    constexpr sampler quadSampler(filter::linear, address::clamp_to_edge);
    float4 color = inputTexture.sample(quadSampler, in.texCoord);
    
    // Apply brightness and contrast
    float3 enhanced = (color.rgb - 0.5) * contrast + 0.5 + brightness;
    enhanced = clamp(enhanced, 0.0, 1.0);
    
    return float4(enhanced, color.a);
}

/// Basic sharpening filter shader (placeholder implementation)
fragment float4 sharpenEnhancement(FragmentInput in [[stage_in]],
                                    texture2d<float> inputTexture [[texture(0)]]) {
    
    constexpr sampler quadSampler(filter::linear, address::clamp_to_edge);
    float4 centerColor = inputTexture.sample(quadSampler, in.texCoord);
    
    // Simple sharpening: enhance edges
    return float4(centerColor.rgb * 1.2 - 0.1, centerColor.a);
}