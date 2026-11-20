from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn is_prime(value: Int64) -> Bool:
    if value < 2:
        return False
    var divisor: Int64 = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True

fn power_mod(base: Int64, exponent: Int64, modulus: Int64) -> Int64:
    var factor = base % modulus
    var remaining = exponent
    var result: Int64 = 1
    while remaining > 0:
        if remaining % 2 == 1:
            result = (result * factor) % modulus
        factor = (factor * factor) % modulus
        remaining = remaining // 2
    return result

@export("binomial_coefficient_lucas")
fn binomial_coefficient_lucas(
    values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3:
        return -1

    let n = values[0]
    let k = values[1]
    let p = values[2]
    if n < 0 or k < 0 or k > n or p < 2 or p > 1009 or not is_prime(p):
        return -1

    var factorial = InlineArray[Int64, 1010]()
    var inverse_factorial = InlineArray[Int64, 1010]()
    factorial[0] = 1
    for i in range(1, Int(p)):
        factorial[i] = (factorial[i - 1] * Int64(i)) % p

    inverse_factorial[Int(p - 1)] = power_mod(factorial[Int(p - 1)], p - 2, p)
    var i = p - 1
    while i > 0:
        inverse_factorial[Int(i - 1)] = (inverse_factorial[Int(i)] * i) % p
        i -= 1

    var remaining_n = n
    var remaining_k = k
    var result: Int64 = 1
    while remaining_n > 0 or remaining_k > 0:
        let digit_n = remaining_n % p
        let digit_k = remaining_k % p
        if digit_k > digit_n:
            return 0
        result = (result * factorial[Int(digit_n)]) % p
        result = (result * inverse_factorial[Int(digit_k)]) % p
        result = (result * inverse_factorial[Int(digit_n - digit_k)]) % p
        remaining_n = remaining_n // p
        remaining_k = remaining_k // p
    return result
