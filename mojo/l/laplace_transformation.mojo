from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import exp

@export("laplace_transformation")
fn laplace_transformation(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 3 or n > 68: return -1.0e300
    let count = v[0]; let s = v[1]; let dt = v[2]
    if count < 1 or count > 64 or n != c_size_t(count + 3) or s < 0 or s > 1000 or dt < 1 or dt > 1000000: return -1.0e300
    var samples = InlineArray[Float64, 64](fill=0.0)
    for i in range(Int(count)):
        if v[3+i] < -1000000 or v[3+i] > 1000000: return -1.0e300
        samples[i] = Float64(v[3+i]) / 1.0e6
    if count == 1: return 0.0
    let sv = Float64(s) / 1000.0; let delta = Float64(dt) / 1.0e6
    let stop = Float64(count - 1) * delta; let step = stop / Float64(count - 1)
    var integrand = InlineArray[Float64, 64](fill=0.0)
    for i in range(Int(count)):
        let t = if i == Int(count)-1: stop else: Float64(i)*step
        integrand[i] = samples[i] * exp(-sv*t)
    var result: Float64 = 0.0
    for i in range(Int(count)-1): result += (delta*(integrand[i]+integrand[i+1]))/2.0
    return result
