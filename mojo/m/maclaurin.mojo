from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import abs, pow

fn maclaurin_factorial(n: Int) -> Float64:
    var f = 1.0
    for i in range(2, n + 1): f *= Float64(i)
    return f

@export("maclaurin")
fn maclaurin(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 3: return -1.0e300
    let mode = v[0]; let xm = v[1]; let em = v[2]
    if mode < 0 or mode > 2 or xm < -2000 or xm > 2000 or em < 1 or em > 250: return -1.0e300
    let x = Float64(xm) / 1000.0; let error = Float64(em) / 1000.0
    var coefficient = 0.0; var result = 0.0
    for i in range(32):
        result += coefficient
        var exponent = i; var sign = 1.0
        if mode == 1: exponent = 2 * i + 1; if i % 2 != 0: sign = -1.0
        elif mode == 2: exponent = 2 * i; if i % 2 != 0: sign = -1.0
        coefficient = (pow(x, Float64(exponent)) / maclaurin_factorial(exponent)) if mode == 0 else sign * pow(x, Float64(exponent)) / maclaurin_factorial(exponent)
        if abs(coefficient) <= error: return result
    return -1.0e300
