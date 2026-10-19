from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn continued_gcd(a_arg: Int64, b_arg: Int64) -> Int64:
    var a = a_arg
    var b = b_arg
    while b != 0:
        let r = a % b
        a = b
        b = r
    return a

@export("continued_fraction")
fn continued_fraction(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    var numerator = input[0]
    var denominator = input[1]
    if numerator < -1000000 or numerator > 1000000 or denominator < -1000000 or denominator > 1000000 or denominator == 0: return -1
    let abs_n = numerator if numerator >= 0 else -numerator
    let abs_d = denominator if denominator >= 0 else -denominator
    let divisor = continued_gcd(abs_n, abs_d)
    numerator /= divisor
    denominator /= divisor
    if denominator < 0:
        numerator = -numerator
        denominator = -denominator
    var coefficients = InlineArray[Int64, 32](0)
    var count: Int64 = 0
    while True:
        var quotient = numerator / denominator
        var remainder = numerator % denominator
        if remainder < 0:
            quotient -= 1
            remainder += denominator
        if count == 32: return -1
        coefficients[count] = quotient
        count += 1
        if remainder == 0: break
        numerator = denominator
        denominator = remainder
    let bytes = count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes: return -2
    for i in range(count):
        let bits = UInt64(coefficients[i])
        for b in range(8): output[8 * i + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes
