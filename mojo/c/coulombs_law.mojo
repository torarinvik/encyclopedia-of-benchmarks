from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("coulombs_law")
fn coulombs_law(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1.0e300
    let q1_raw = values[0]
    let q2_raw = values[1]
    let distance_raw = values[2]
    if q1_raw == 0 or q2_raw == 0 or q1_raw < -1000000 or q1_raw > 1000000 or q2_raw < -1000000 or q2_raw > 1000000 or distance_raw < 1 or distance_raw > 1000000: return -1.0e300
    let q1 = Float64(q1_raw) / 1000000.0
    let q2 = Float64(q2_raw) / 1000000.0
    let distance = Float64(distance_raw) / 1000.0
    var product = q1 * q2
    if product < 0.0: product = -product
    return 8987551792.3 * product / (distance * distance)
