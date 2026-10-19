from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime INVALID: Float64 = -1.0e300
@export("sum_of_arithmetic_series")
fn sum_of_arithmetic_series(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 3: return INVALID
    let a=v[0]; let d=v[1]; let terms=v[2]
    if a < -1000 or a > 1000 or d < -1000 or d > 1000 or terms < 1 or terms > 1000: return INVALID
    return Float64(terms * (2*a + (terms-1)*d) / 2)
