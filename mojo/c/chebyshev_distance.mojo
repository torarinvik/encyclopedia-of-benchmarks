from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("chebyshev_distance")
fn chebyshev_distance(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return -1
    let dimension = values[0]
    if dimension < 1 or dimension > 128 or length != 1 + 2 * dimension: return -1
    var maximum: Int64 = 0
    for i in range(dimension):
        let a = values[1 + i]
        let b = values[1 + dimension + i]
        if a < -1000000000 or a > 1000000000 or b < -1000000000 or b > 1000000000: return -1
        var difference = a - b
        if difference < 0: difference = -difference
        if difference > maximum: maximum = difference
    return maximum
