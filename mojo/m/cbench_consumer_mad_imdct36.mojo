# Independent bounded IMDCT profile; see the package LICENSE.txt.
from std.ffi import c_size_t
from std.math import cos, isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cbench_consumer_mad_imdct36")
fn cbench_consumer_mad_imdct36(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 18:
        return -1
    var coefficients = InlineArray[Float64, 18](fill=0.0)
    for i in range(18):
        let value = input[i]
        if not isfinite(value) or value < -16.0 or value > 16.0:
            return -1
        coefficients[i] = value
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 36:
        return -2
    let pi: Float64 = 3.14159265358979323846
    var result = InlineArray[Float64, 36](fill=0.0)
    for n in range(36):
        var sum: Float64 = 0.0
        for k in range(18):
            let angle = pi * Float64(2 * n + 19) * Float64(2 * k + 1) / 72.0
            sum += coefficients[k] * cos(angle)
        result[n] = sum
    for i in range(36): output[i] = result[i]
    return 36
