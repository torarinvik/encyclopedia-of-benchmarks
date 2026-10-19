from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("faraday_lenz_law")
fn faraday_lenz_law(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3 or values[0] < -1000000000 or values[0] > 1000000000 or values[1] < -1000000000 or values[1] > 1000000000 or values[2] < 1 or values[2] > 1000000000: return -9223372036854775808
    let numerator = -(values[0] - values[1]) * 10
    let magnitude = -numerator if numerator < 0 else numerator
    var q = magnitude / values[2]
    let r = magnitude % values[2]
    if 2 * r > values[2] or (2 * r == values[2] and q % 2 != 0): q += 1
    return -q if numerator < 0 else q
