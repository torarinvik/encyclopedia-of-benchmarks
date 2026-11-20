from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn gcd_i64(a_input: Int64, b_input: Int64) -> Int64:
    var a = a_input
    var b = b_input
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    return a

fn pow_mod_i64(base_input: Int64, exponent_input: Int64, modulus: Int64) -> Int64:
    var base = base_input % modulus
    var exponent = exponent_input
    var result: Int64 = 1
    while exponent > 0:
        if exponent % 2 != 0: result = result * base % modulus
        base = base * base % modulus
        exponent = exponent // 2
    return result

fn totient_i64(value: Int64) -> Int64:
    var remaining = value
    var result = value
    var prime: Int64 = 2
    while prime * prime <= remaining:
        if remaining % prime == 0:
            result = result // prime * (prime - 1)
            while remaining % prime == 0: remaining = remaining // prime
        prime += 1
    if remaining > 1: result = result // remaining * (remaining - 1)
    return result

fn reduce_order(base: Int64, modulus: Int64, initial_order: Int64) -> Int64:
    var remaining = initial_order
    var order = initial_order
    var prime: Int64 = 2
    while prime * prime <= remaining:
        if remaining % prime == 0:
            while remaining % prime == 0: remaining = remaining // prime
            while order % prime == 0 and pow_mod_i64(base, order // prime, modulus) == 1:
                order = order // prime
        prime += 1
    if remaining > 1:
        while order % remaining == 0 and pow_mod_i64(base, order // remaining, modulus) == 1:
            order = order // remaining
    return order

@export("multiplicative_order")
fn multiplicative_order(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let base = input[0]
    let modulus = input[1]
    if modulus < 2 or modulus > 1000 or base < 0 or base >= modulus: return -1
    if gcd_i64(base, modulus) != 1: return 0
    return reduce_order(base, modulus, totient_i64(modulus))
