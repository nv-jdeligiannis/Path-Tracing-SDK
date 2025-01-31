/*
* Copyright (c) 2023, NVIDIA CORPORATION.  All rights reserved.
*
* NVIDIA CORPORATION and its licensors retain all intellectual property
* and proprietary rights in and to this software, related documentation
* and any modifications thereto.  Any use, reproduction, disclosure or
* distribution of this software and related documentation without an express
* license agreement from NVIDIA CORPORATION is strictly prohibited.
*/

#ifndef __SAMPLING_HLSLI__ // using instead of "#pragma once" due to https://github.com/microsoft/DirectXShaderCompiler/issues/3943
#define __SAMPLING_HLSLI__

#include "Config.h"

enum class SampleGeneratorEffectSeed : uint32_t
{
    Base                    = 0,        // this is the default state that the SampleGenerator starts from
    ScatterBSDF             = 1,
    NextEventEstimation     = 2,
    NextEventEstimationLoc  = 3,
    NextEventEstimationDist = 4,
    RussianRoulette         = 5,
};

// performance optimization for LD sampling - will stop using LD sampling after selected diffuse bounces (1 to stop after first diffuse, 2 after 2nd, etc.)
#define DisableLowDiscrepancySamplingAfterDiffuseBounceCount    2

// Note, compared to Falcor we've completely switched to 'stateless' random/sample generators to avoid storing additional per-path data.
// That means that each sample generator is seeded not only by pixel position and sample index but also 'vertexIndex', which increases
// chances of overlap.

#include "StatelessSampleGenerators.hlsli"
#if 0   // fast uniform
#define SampleGenerator StatelessUniformSampleGenerator
#elif 1 // low discrepancy
#define SampleGenerator StatelessLowDiscrepancySampleGenerator
#else   // slow uniform with good distribution for many-sample (1mil+) references
#include "StatelessHQUniformSampleGenerator.hlsli"
#define SampleGenerator StatelessHQUniformSampleGenerator
#endif


/** Convenience functions for generating 1D/2D/3D values in the range [0,1).
*/
float sampleNext1D( inout SampleGenerator sampleGenerator )
{
    // Use upper 24 bits and divide by 2^24 to get a number u in [0,1).
    // In floating-point precision this also ensures that 1.0-u != 0.0.
    uint bits = sampleGenerator.next();
    return (bits >> 8) * 0x1p-24;
}
float2 sampleNext2D( inout SampleGenerator sampleGenerator )
{
#ifndef SAMPLER_HAS_SPECIALIZED_2D3D
    float2 sample;
    // Don't use the float2 initializer to ensure consistent order of evaluation.
    sample.x = sampleNext1D(sampleGenerator);
    sample.y = sampleNext1D(sampleGenerator);
    return sample;
#else
    uint2 bits = sampleGenerator.next2D();
    return (bits >> 8) * 0x1p-24.xx;
#endif
}
float3 sampleNext3D( inout SampleGenerator sampleGenerator )
{
#ifndef SAMPLER_HAS_SPECIALIZED_2D3D
    float3 sample;
    // Don't use the float3 initializer to ensure consistent order of evaluation.
    sample.x = sampleNext1D(sampleGenerator);
    sample.y = sampleNext1D(sampleGenerator);
    sample.z = sampleNext1D(sampleGenerator);
    return sample;
#else
    uint3 bits = sampleGenerator.next3D();
    return (bits >> 8) * 0x1p-24.xxx;
#endif
}
float4 sampleNext4D( inout SampleGenerator sampleGenerator )
{
#ifndef SAMPLER_HAS_SPECIALIZED_2D3D
    float4 sample;
    // Don't use the float3 initializer to ensure consistent order of evaluation.
    sample.x = sampleNext1D(sampleGenerator);
    sample.y = sampleNext1D(sampleGenerator);
    sample.z = sampleNext1D(sampleGenerator);
    sample.w = sampleNext1D(sampleGenerator);
    return sample;
#else
    uint3 bits = sampleGenerator.next3D();
    return (bits >> 8) * 0x1p-24.xxx;
#endif
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#endif // __SAMPLING_HLSLI__
