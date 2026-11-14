# Independent RSynth natural-source profile; see package rights notice.
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cbench_rsynth_natural_glottal_sample")
fn cbench_rsynth_natural_glottal_sample(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                                         output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 2: return -1
    let a = input[0]
    let b = input[1]
    if not isfinite(a) or not isfinite(b) or a < 40.0 or a > 263.0 or b < 0.0 or b > 299.0: return -1
    let nopen = Int(a)
    let index = Int(b)
    if Float64(nopen) != a or Float64(index) != b: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 1: return -2
    var result = Float32(0.0)
    if index < nopen:
        let coefficient = Float32(1920000 // (nopen * nopen))
        let product = Float32(coefficient * Float32(nopen))
        var slope = Float32(Float64(product) * 0.333)
        var wave = Float32(0.0)
        for _ in range(index + 1):
            slope = Float32(slope - coefficient)
            wave = Float32(wave + slope)
        result = Float32(Float64(wave) * 0.028)
    output[0] = Float64(result)
    return 1
