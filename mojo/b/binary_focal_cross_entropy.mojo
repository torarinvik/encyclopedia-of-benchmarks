from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import log

comptime INVALID_RESULT: Float64 = -1.0e300
@export("binary_focal_cross_entropy")
fn binary_focal_cross_entropy(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 513: return INVALID_RESULT
    let n_value = input[0]
    if n_value < 1 or n_value > 256 or length != c_size_t(1 + 2 * n_value): return INVALID_RESULT
    let n = Int(n_value)
    for i in range(n):
        if (input[1 + i] != 0 and input[1 + i] != 1) or input[1 + n + i] < 0 or input[1 + n + i] > 1_000_000: return INVALID_RESULT
    var total: Float64 = 0.0
    for i in range(n):
        let y = Float64(input[1 + i])
        var p = Float64(input[1 + n + i]) / 1_000_000.0
        p = max(1.0e-15, min(1.0 - 1.0e-15, p))
        let q = 1.0 - p
        total -= 0.25 * q * q * y * log(p) + 0.75 * p * p * (1.0 - y) * log(q)
    return total / Float64(n)
