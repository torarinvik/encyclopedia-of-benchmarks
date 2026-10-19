from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("complementary_filter")
fn complementary_filter(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2: return -1.0e300
    let coeff = values[0]
    let count = values[1]
    if coeff < 1 or coeff >= 1000000 or count < 1 or count > 32 or length != 2 + 3 * count: return -1.0e300
    for i in range(count):
        let rate = values[2 + 3 * i]
        let reference = values[3 + 3 * i]
        let elapsed = values[4 + 3 * i]
        if rate < -1000000 or rate > 1000000 or reference < -1000000 or reference > 1000000 or elapsed < 1 or elapsed > 1000000: return -1.0e300
    let coefficient = Float64(coeff) / 1000000.0
    var value: Float64 = 0.0
    for i in range(count):
        let rate = Float64(values[2 + 3 * i]) / 1000000.0
        let reference = Float64(values[3 + 3 * i]) / 1000000.0
        let elapsed = Float64(values[4 + 3 * i]) / 1000000.0
        if i == 0: value = reference
        else: value = coefficient * (value + rate * elapsed) + (1.0 - coefficient) * reference
    return value
