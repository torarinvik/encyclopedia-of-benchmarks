# Independent bounded long-block MDCT; see package license notice.
from std.ffi import c_size_t
from std.math import cos, isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("mibench_lame_mdct_long")
fn mibench_lame_mdct_long(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 18:
        return -1
    var values = InlineArray[Float64, 18](fill=0.0)
    for i in range(18):
        let value = input[i]
        if not isfinite(value) or value < -16.0 or value > 16.0:
            return -1
        values[i] = value
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 18:
        return -2
    let pi: Float64 = 3.14159265358979323846
    var staged = InlineArray[Float64, 18](fill=0.0)
    for m in range(18):
        var sum: Float64 = 0.0
        for k in range(18):
            let offset = if k < 9: 38 else: 74
            let angle = pi * Float64(2 * m + 1) * Float64(4 * k + offset) / 144.0
            sum += values[k] * cos(angle)
        staged[m] = (4.0 / 36.0) * sum
    for i in range(18):
        output[i] = staged[i]
    return 18
