//
//  PBRLighting.metal  
//  SceneReconstruction
//
//  PBR lighting shader for physically-based rendering (post-process effect)
//

#include <metal_stdlib>
using namespace metal;

// Constants for physically-based rendering
static constant float PI = 3.14159265358979323846f;

// Vertex output structure - must be defined first for use in other functions
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float3 normal;
};

// Material parameters structure
struct PBRMaterial {
    float metallic;
    float roughness;
    float ambientOcclusion;
};

// Light parameters structure  
struct PBRLight {
    float3 lightDirection;
    float3 lightColor;
    float intensity;
    float ambientIntensity;
};

// Simple Fresnel calculation (Schlick approximation)
float3 fresnelSchlick(float cosTheta, float3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - max(cosTheta, 0.0), 5.0);
}

// Geometric occlusion term (Smith method)
float geometrySmith(float NdotV, float NdotL, float roughness) {
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;  // Approximation for direct lighting
    
    float denomV = NdotV * (1.0 - k) + k;
    float denomL = NdotL * (1.0 - k) + k;
    
    return NdotV * NdotL / max(denomV * denomL, 0.001);
}

// Normal distribution function (GGX)
float distributionGGX(float NdotH, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH2 = NdotH * NdotH;
    
    float num = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
    
    return num / max(denom, 0.001);
}

// Calculate PBR lighting for a single light source
float3 calculatePBRLighting(float3 N, float3 V, float3 L,
                           float3 baseColor, float metallic, float roughness) {
    // Half vector between view and light direction
    float3 H = normalize(V + L);
    
    // Dot products
    float NdotL = max(dot(N, L), 0.0);
    float NdotV = max(dot(N, V), 0.0);
    float NdotH = max(dot(N, H), 0.0);
    float VdotH = max(dot(V, H), 0.0);
    
    // Fresnel
    float3 F0 = float3(0.04);  // Base reflectivity (dielectric)
    F0 = mix(F0, baseColor, metallic);
    float3 F = fresnelSchlick(VdotH, F0);
    
    // Specular distribution
    float D = distributionGGX(NdotH, roughness);
    
    // Geometry occlusion  
    float G = geometrySmith(NdotV, NdotL, roughness);
    
    // Specular BRDF
    float3 specular = (D * G * F) / max(4.0 * NdotV * NdotL, 0.001);
    
    // Diffuse BRDF (energy conservation)
    float3 kS = F;  // Reflectance fraction
    float3 kD = float3(1.0) - kS;  // Refractance fraction
    kD *= 1.0 - metallic;  // Metallic surfaces don't have diffuse
    
    float3 diffuse = (kD * baseColor / PI + specular) * NdotL;
    
    return diffuse;
}

// Full-screen PBR lighting pass
fragment float4 pbrLightingFragment(
    VertexOut in [[stage_in]],
    texture2d<float> colorTexture [[texture(0)]],
    constant PBRLight& lightParams [[buffer(1)]],
    constant PBRMaterial& materialParams [[buffer(2)]]
) {
    constexpr sampler quadSampler(filter::linear, address::clamp_to_edge);
    
    // Sample base color from input texture
    float4 color = colorTexture.sample(quadSampler, in.texCoord);
    
    // Calculate normal (simplified - using view space z for depth-based normals)
    float3 N = normalize(float3(in.normal.xy, sqrt(1.0 - dot(in.normal.xy, in.normal.xy))));
    
    // View direction (camera looking down -Z axis)
    float3 V = normalize(float3(0.0, 0.0, -1.0));
    
    // Light direction
    float3 L = normalize(lightParams.lightDirection);
    
    // Apply PBR lighting calculation
    float3 result = calculatePBRLighting(N, V, L, color.rgb, materialParams.metallic, materialParams.roughness);
    
    return float4(result + color.rgb * lightParams.ambientIntensity, color.a);
}

// Vertex shader for full-screen quad
vertex VertexOut pbrLightingVertex(
    uint vertexID [[vertex_id]],
    constant float2* positionBuffer [[buffer(0)]]
) {
    VertexOut out;
    
    // Full-screen quad vertices (clip space: -1 to 1)
    const float2 positions[4] = {
        float2(-1.0, -1.0),
        float2(1.0, -1.0),
        float2(-1.0, 1.0),
        float2(1.0, 1.0)
    };
    
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = float2(positions[vertexID] * 0.5 + 0.5);  // Convert to UV coordinates
    out.normal = float3(0.0, 0.0, 1.0);  // Normal pointing towards camera
    
    return out;
}