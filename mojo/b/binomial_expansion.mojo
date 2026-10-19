from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime INVALID: Int64 = -9_223_372_036_854_775_808

fn integer_power(base: Int64, exponent: Int) -> Int64:
    var result: Int64 = 1
    for _ in range(exponent): result *= base
    return result

@export("binomial_expansion")
fn binomial_expansion(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return INVALID
    let a = input[0]; let b = input[1]; let n = input[2]
    if a < -2 or a > 2 or b < -2 or b > 2 or n < 0 or n > 31: return INVALID
    var coefficient: Int64 = 1; var result: Int64 = 0
    for i in range(Int(n) + 1):
        result += coefficient * integer_power(a, Int(n) - i) * integer_power(b, i)
        if i < Int(n): coefficient = (coefficient * (n - i)) // (i + 1)
    return result
