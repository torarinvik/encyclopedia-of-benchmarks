from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn bisect2_f(x: Float64) -> Float64: return 10.0 - x * x

@export("bisection_2")
fn bisection_2(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1.0e300
    let lm = input[0]; let rm = input[1]
    if lm < -100000 or lm > 100000 or rm < -100000 or rm > 100000 or lm >= rm: return -1.0e300
    var a = Float64(lm) / 1000.0; var b = Float64(rm) / 1000.0
    if bisect2_f(a) * bisect2_f(b) >= 0.0: return -1.0e300
    var c = a
    while b - a >= 0.01:
        c = (a + b) / 2.0
        if bisect2_f(c) == 0.0: break
        if bisect2_f(c) * bisect2_f(a) < 0.0: b = c
        else: a = c
    return c
