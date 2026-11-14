# Independent RSynth impulsive-source profile; see package rights notice.
from std.ffi import c_size_t
from std.math import exp, isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cbench_rsynth_impulsive_glottal_sample")
fn cbench_rsynth_impulsive_glottal_sample(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                                           output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 2: return -1
    let a = input[0]
    let b = input[1]
    if not isfinite(a) or not isfinite(b) or a < 40.0 or a > 263.0 or b < 0.0 or b > 299.0: return -1
    let nopen = Int(a)
    let target = Int(b)
    if Float64(nopen) != a or Float64(target) != b: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 1: return -2
    let minus_pi = Float32(-3.141592653589793 / 8000.0)
    let bandwidth = 8000 // nopen
    let radius = Float32(exp(Float64(minus_pi) * Float64(bandwidth)))
    let c = Float32(-(radius * radius))
    let coeff_b = Float32(Float64(radius) * 2.0)
    var coeff_a = Float32(1.0 - Float64(coeff_b) - Float64(c))
    let gain = Float32(Float64(nopen) * 0.00833)
    coeff_a = Float32(coeff_a * Float32(gain * gain))
    var p1 = Float32(0.0)
    var p2 = Float32(0.0)
    for i in range(target + 1):
        var impulse = Float32(0.0)
        if i == 1: impulse = Float32(13000000.0)
        elif i == 2: impulse = Float32(-13000000.0)
        var sample = Float32(Float32(coeff_a * impulse) + Float32(coeff_b * p1))
        sample = Float32(sample + Float32(c * p2))
        p2 = p1
        p1 = sample
    output[0] = Float64(p1)
    return 1
