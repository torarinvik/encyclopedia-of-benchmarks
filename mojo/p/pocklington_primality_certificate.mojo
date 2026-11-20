from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N: Int64 = 65535
const MAX_FACTORS: Int64 = 6
const MAX_EXPONENT: Int64 = 16
const MAX_LENGTH = 22

fn gcd_i64(left_value: Int64, right_value: Int64) -> Int64:
    var left = left_value
    var right = right_value
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

fn is_prime(value: Int64) -> Bool:
    if value < 2:
        return False
    var divisor: Int64 = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        if divisor == 2:
            divisor = 3
        else:
            divisor += 2
    return True

fn pow_mod(base: Int64, exponent_value: Int64, modulus: Int64) -> Int64:
    var result: Int64 = 1
    var factor = base % modulus
    var exponent = exponent_value
    while exponent > 0:
        if (exponent & 1) != 0:
            result = (result * factor) % modulus
        factor = (factor * factor) % modulus
        exponent >>= 1
    return result

fn verify_certificate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Int64:
    if length < 2 or length > MAX_LENGTH:
        return -1
    let n = input[0]
    let count = input[1]
    if n < 3 or n > MAX_N or count < 1 or count > MAX_FACTORS:
        return -1
    if length != 3 + 3 * count:
        return -1

    var factored_part: Int64 = 1
    var previous_prime: Int64 = 1
    var index: Int64 = 0
    while index < count:
        let offset = 2 + 3 * index
        let prime = input[offset]
        let exponent = input[offset + 1]
        let witness = input[offset + 2]
        if prime <= previous_prime or prime < 2 or exponent < 1 or exponent > MAX_EXPONENT:
            return -1
        if witness < 1 or witness >= n or not is_prime(prime):
            return -1
        previous_prime = prime
        var power_index: Int64 = 0
        while power_index < exponent:
            if factored_part > (n - 1) // prime:
                return -1
            factored_part *= prime
            power_index += 1
        index += 1

    let cofactor = input[2 + 3 * count]
    if cofactor < 1 or cofactor >= n or factored_part * cofactor != n - 1:
        return -1
    if factored_part * factored_part <= n:
        return 0

    index = 0
    while index < count:
        let offset = 2 + 3 * index
        let prime = input[offset]
        let witness = input[offset + 2]
        if pow_mod(witness, n - 1, n) != 1:
            return 0
        let reduced = pow_mod(witness, (n - 1) // prime, n)
        let difference = (reduced + n - 1) % n
        if gcd_i64(difference, n) != 1:
            return 0
        index += 1
    return 1

@export("pocklington_primality_certificate")
fn pocklington_primality_certificate(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                    length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_LENGTH:
        return -1
    return verify_certificate(input, Int(length))
