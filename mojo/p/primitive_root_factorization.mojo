from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_PRIME = 4093

fn is_prime(value: Int64) -> Bool:
    if value < 2: return False
    var divisor: Int64 = 2
    while divisor * divisor <= value:
        if value % divisor == 0: return False
        divisor += 1
    return True

fn power_mod(base_input: Int64, exponent_input: Int64, modulus: Int64) -> Int64:
    var base = base_input
    var exponent = exponent_input
    var result: Int64 = 1
    while exponent > 0:
        if exponent % 2 != 0: result = result * base % modulus
        base = base * base % modulus
        exponent = exponent // 2
    return result

@export("primitive_root_factorization")
fn primitive_root_factorization(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let prime = input[0]
    if prime < 2 or prime > MAX_PRIME or not is_prime(prime): return -1
    if prime == 2: return 1

    var factors = InlineArray[Int64, 16](fill=0)
    var factor_count = 0
    var remaining = prime - 1
    var divisor: Int64 = 2
    while divisor * divisor <= remaining:
        if remaining % divisor == 0:
            factors[factor_count] = divisor
            factor_count += 1
            while remaining % divisor == 0: remaining = remaining // divisor
        divisor += 1
    if remaining > 1:
        factors[factor_count] = remaining
        factor_count += 1

    for candidate in range(2, Int(prime)):
        var valid = True
        for index in range(factor_count):
            if power_mod(Int64(candidate), (prime - 1) // factors[index], prime) == 1:
                valid = False
                break
        if valid: return Int64(candidate)
    return -1
