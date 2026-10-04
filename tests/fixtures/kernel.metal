#include <metal_stdlib>
using namespace metal;

kernel void add(device const float* a [[buffer(0)]],
                device const float* b [[buffer(1)]],
                device float* output [[buffer(2)]],
                uint index [[thread_position_in_grid]]) {
    output[index] = a[index] + b[index];
}
