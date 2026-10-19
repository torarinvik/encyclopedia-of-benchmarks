from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("manhattan_distance")
fn manhattan_distance(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 3: return -1.0e300
    let d = v[0]
    if d < 1 or d > 16 or n != c_size_t(1 + 2 * d): return -1.0e300
    var total: Int64 = 0
    for i in range(Int(d)):
        let a = v[1 + i]; let b = v[1 + Int(d) + i]
        if a < -1_000_000 or a > 1_000_000 or b < -1_000_000 or b > 1_000_000: return -1.0e300
        let diff = a - b
        total += diff if diff >= 0 else -diff
    return Float64(total)
