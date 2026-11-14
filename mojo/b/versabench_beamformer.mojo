# Bounded complex beamforming profile; see package LICENSE for attribution.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("versabench_beamformer")
fn versabench_beamformer(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 48: return -1
    var samples = InlineArray[Float32, 48](fill=0)
    for index in range(48):
        let value = input[index]
        if value != value or value < -128.0 or value > 128.0: return -1
        samples[index] = Float32(value)
    var real = Float32(0)
    var imag = Float32(0)
    for channel in range(12):
        let base = 4 * channel
        let wr = samples[base]
        let wi = samples[base + 1]
        let xr = samples[base + 2]
        let xi = samples[base + 3]
        let rr = Float32(wr * xr)
        let ii = Float32(wi * xi)
        let ri = Float32(wr * xi)
        let ir = Float32(wi * xr)
        let real_term = Float32(rr - ii)
        let imag_term = Float32(ri + ir)
        real = Float32(real + real_term)
        imag = Float32(imag + imag_term)
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 2: return -2
    output[0] = Float64(real)
    output[1] = Float64(imag)
    return 2
