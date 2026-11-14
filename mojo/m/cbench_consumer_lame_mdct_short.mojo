# Independent bounded short-block MDCT profile; see package LICENSE.txt.
from std.ffi import c_size_t
from std.math import cos, isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cbench_consumer_lame_mdct_short")
fn cbench_consumer_lame_mdct_short(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 18:
        return -1
    var values = InlineArray[Float64, 18](fill=0.0)
    for i in range(18):
        let value = input[i]
        if not isfinite(value) or value < -32768.0 or value > 32768.0:
            return -1
        values[i] = value
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 18:
        return -2
    let pi: Float64 = 3.14159265358979323846
    var coefficients = InlineArray[Float64, 36](fill=0.0)
    for i in range(3):
        let weight = cos(pi / 12.0 * (Float64(i) + 0.5)) * 0.030526638 / 32768.0 * (4.0 / 12.0)
        for m in range(6):
            coefficients[6 * m + i] = weight * cos((pi / 48.0) * Float64(2 * m + 1) * Float64(4 * i + 14))
            coefficients[6 * m + i + 3] = weight * cos((pi / 48.0) * Float64(2 * m + 1) * Float64(4 * i + 38))
    var staged = InlineArray[Float64, 18](fill=0.0)
    for m in range(6):
        for window in range(3):
            var sum = coefficients[6 * m] * values[6 * window]
            for i in range(1, 6):
                sum += coefficients[6 * m + i] * values[6 * window + i]
            staged[3 * m + window] = sum
    for i in range(18): output[i] = staged[i]
    return 18
