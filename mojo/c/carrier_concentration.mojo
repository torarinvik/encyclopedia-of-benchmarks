from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt

@export("carrier_concentration")
fn carrier_concentration(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1.0e300
    let electrons = values[0]
    let holes = values[1]
    let intrinsic = values[2]
    if electrons < 0 or electrons > 1000000 or holes < 0 or holes > 1000000 or intrinsic < 0 or intrinsic > 1000000: return -1.0e300
    var zero_count: Int64 = 0
    if electrons == 0: zero_count += 1
    if holes == 0: zero_count += 1
    if intrinsic == 0: zero_count += 1
    if zero_count != 1: return -1.0e300
    if electrons == 0: return Float64(intrinsic * intrinsic) / Float64(holes)
    if holes == 0: return Float64(intrinsic * intrinsic) / Float64(electrons)
    return sqrt(Float64(electrons * holes))
