from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("alternating_harmonic_series")
fn alternating_harmonic_series(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1:
        return -1
    let count = values[0]
    if count < 0 or count > 1000 or length != c_size_t(1 + 2 * count):
        return -1
    if count == 0:
        return 0
    for i in range(count):
        let numerator = values[1 + 2 * i]
        let denominator = values[2 + 2 * i]
        if numerator < -1000 or numerator > 1000 or denominator < 1 or denominator > 1000:
            return -1
    for i in range(count):
        let numerator = values[1 + 2 * i]
        let denominator = values[2 + 2 * i]
        let term = i + 1
        var sign: Int64 = 1
        if i % 2 == 1:
            sign = -1
        var error = numerator * term - sign * denominator
        if error < 0:
            error = -error
        if error * 1000000000 > denominator * term:
            return 0
    return 1
