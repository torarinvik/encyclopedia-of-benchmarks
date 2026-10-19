from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import cos

@export("malus_law")
fn malus_law(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 2: return -1.0e300
    let intensity = v[0]; let angle = v[1]
    if intensity < 0 or intensity > 1000 or angle < 0 or angle > 360: return -1.0e300
    let radians = (Float64(angle) * 3.141592653589793238462643383279502884) / 180.0
    let cosine = cos(radians)
    return Float64(intensity) * (cosine * cosine)
