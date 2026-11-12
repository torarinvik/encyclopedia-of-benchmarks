from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MODULUS = Int64(998244353)
alias MAX_DEGREE = 256

fn seppl_mod_pow(base_input: Int64, exponent_input: Int64) -> Int64:
    var base = base_input
    var exponent = exponent_input
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) == 1:
            result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    return result

@export("sum_of_exponential_times_polynomial_limit")
fn sum_of_exponential_times_polynomial_limit(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2:
        return -1
    let r = input[0]
    let degree_value = input[1]
    if r < 0 or r >= MODULUS or r == 1 or degree_value < 0 or degree_value > MAX_DEGREE:
        return -1
    let degree = Int(degree_value)
    let denominator = (1 - r + MODULUS) % MODULUS
    let inverse = seppl_mod_pow(denominator, MODULUS - 2)
    if degree == 0:
        return inverse

    var row = InlineArray[Int64, 257]()
    var next_row = InlineArray[Int64, 257]()
    row[0] = 1
    for n in range(1, degree + 1):
        for k in range(n + 1):
            var value: Int64 = 0
            if k > 0:
                value += Int64(n - k) * row[k - 1]
            if k < n:
                value += Int64(k + 1) * row[k]
            next_row[k] = value % MODULUS
        for k in range(n + 1):
            row[k] = next_row[k]
            next_row[k] = 0

    var eulerian_value: Int64 = 0
    for k in range(degree, 0, -1):
        eulerian_value = (eulerian_value * r + row[k - 1]) % MODULUS
    let denominator_power = seppl_mod_pow(inverse, Int64(degree + 1))
    return r * eulerian_value % MODULUS * denominator_power % MODULUS
