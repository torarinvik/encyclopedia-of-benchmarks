from std.math import isfinite

fn fib_matrix_mul_sum(a: UInt64, b: UInt64, c: UInt64, d: UInt64, modulus: UInt64) -> UInt64:
    return ((a * b) % modulus + (c * d) % modulus) % modulus

@export("fibonacci_matrix_exponentiation")
fn fibonacci_matrix_exponentiation(index_input: Float64, modulus_input: Float64) abi("C") -> Float64:
    if not isfinite(index_input) or not isfinite(modulus_input) or index_input < 1.0 or index_input > 9007199254740991.0 or modulus_input < 1.0 or modulus_input > 4294967295.0: return -1.0
    let index = UInt64(index_input)
    let modulus = UInt64(modulus_input)
    if Float64(index) != index_input or Float64(modulus) != modulus_input: return -1.0
    var r00 = UInt64(1) % modulus
    var r01: UInt64 = 0
    var r10: UInt64 = 0
    var r11 = UInt64(1) % modulus
    var t00: UInt64 = 0
    var t01 = UInt64(1) % modulus
    var t10 = UInt64(1) % modulus
    var t11 = UInt64(1) % modulus
    var exponent = index - 1
    while exponent > 0:
        if exponent % 2 == 1:
            let n00 = fib_matrix_mul_sum(r00, t00, r01, t10, modulus)
            let n01 = fib_matrix_mul_sum(r00, t01, r01, t11, modulus)
            let n10 = fib_matrix_mul_sum(r10, t00, r11, t10, modulus)
            let n11 = fib_matrix_mul_sum(r10, t01, r11, t11, modulus)
            r00=n00; r01=n01; r10=n10; r11=n11
            exponent -= 1
        else:
            let n00 = fib_matrix_mul_sum(t00, t00, t01, t10, modulus)
            let n01 = fib_matrix_mul_sum(t00, t01, t01, t11, modulus)
            let n10 = fib_matrix_mul_sum(t10, t00, t11, t10, modulus)
            let n11 = fib_matrix_mul_sum(t10, t01, t11, t11, modulus)
            t00=n00; t01=n01; t10=n10; t11=n11
            exponent /= 2
    return Float64((r00 + r10) % modulus)
