from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import floor

@export("average_absolute_deviation_rounded")
fn average_absolute_deviation_rounded(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 256: return -1.0e300
    var sum: Float64 = 0.0
    for i in range(Int(length)):
        if values[i] < -2147483648 or values[i] > 2147483647: return -1.0e300
        sum += Float64(values[i])
    let mean = sum / Float64(length)
    var deviation_sum: Float64 = 0.0
    for i in range(Int(length)):
        let value = Float64(values[i])
        if value >= mean: deviation_sum += value - mean
        else: deviation_sum += mean - value
    let scaled = (deviation_sum / Float64(length)) * 100.0
    var rounded = floor(scaled)
    let fraction = scaled - rounded
    if fraction > 0.5 or (fraction == 0.5 and Int64(rounded) % 2 != 0): rounded += 1.0
    return rounded / 100.0
