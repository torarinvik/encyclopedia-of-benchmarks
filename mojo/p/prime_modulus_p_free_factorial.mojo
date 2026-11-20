from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_PRIME = 1009

fn pff_is_prime(value: Int64) -> Bool:
    if value < 2:
        return False
    var divisor: Int64 = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 1
    return True

@export("prime_modulus_p_free_factorial")
fn prime_modulus_p_free_factorial(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != c_size_t(2):
        return -1
    let n = input[0]
    let prime = input[1]
    if n < 0 or prime < 2 or prime > Int64(MAX_PRIME):
        return -1
    if not pff_is_prime(prime):
        return -1

    let prime_size = Int(prime)
    var factorial = InlineArray[Int64, MAX_PRIME]()
    factorial[0] = 1
    for value in range(1, prime_size):
        factorial[value] = factorial[value - 1] * Int64(value) % prime

    var result: Int64 = 1
    var remaining = n
    while remaining > 0:
        let quotient = remaining // prime
        let residue = Int(remaining % prime)
        var block = factorial[residue]
        if quotient % 2 != 0:
            block = (prime - block) % prime
        result = result * block % prime
        remaining = quotient
    return result
