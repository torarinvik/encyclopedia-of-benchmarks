from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("alternate_harmonic_series")
fn alternate_harmonic_series(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1:
        return -1
    let count = values[0]
    if count < 1 or count > 1000 or length != c_size_t(1 + 2 * count):
        return -1
    for i in range(count):
        let numerator = values[1 + 2 * i]
        let denominator = values[2 + 2 * i]
        if numerator < -1000 or numerator > 1000 or numerator == 0 or denominator < 1 or denominator > 1000:
            return -1
    var prev_diff_num: Int64 = 0
    var prev_diff_den: Int64 = 1
    var prev_mag: Int64 = 0
    var prev_den: Int64 = 0
    for i in range(count):
        let numerator = values[1 + 2 * i]
        let denominator = values[2 + 2 * i]
        var magnitude = numerator
        if magnitude < 0: magnitude = -magnitude
        if i > 0:
            if i > 1 and ((numerator < 0) == (values[1 + 2 * (i - 1)] < 0)):
                return 0
            let diff_num = denominator * prev_mag - prev_den * magnitude
            let diff_den = magnitude * prev_mag
            if i > 1 and diff_num * prev_diff_den != prev_diff_num * diff_den:
                return 0
            prev_diff_num = diff_num
            prev_diff_den = diff_den
        prev_mag = magnitude
        prev_den = denominator
    return 1
