from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_DEGREE = 4
const MAX_PRIME = 43
const MAX_EXPONENT = 6
const MAX_MODULUS = 100000
const MAX_LENGTH = 10

fn normalized_mod(value: Int64, modulus: Int64) -> Int64:
    var result = value % modulus
    if result < 0: result += modulus
    return result

fn is_prime(value: Int64) -> Bool:
    if value < 2: return False
    for divisor in range(2, Int(value) + 1):
        if divisor * divisor > Int(value): break
        if Int(value) % divisor == 0: return False
    return True

fn evaluate(input: UnsafePointer[Int64, ImmutAnyOrigin], degree: Int64,
            x: Int64, modulus: Int64) -> Int64:
    var result: Int64 = 0
    var index = Int(degree)
    while index >= 0:
        result = normalized_mod(result * x + input[4 + index], modulus)
        index -= 1
    return result

fn derivative(input: UnsafePointer[Int64, ImmutAnyOrigin], degree: Int64,
               x: Int64, prime: Int64) -> Int64:
    var result: Int64 = 0
    var index = Int(degree)
    while index >= 1:
        result = normalized_mod(result * x + Int64(index) * input[4 + index], prime)
        index -= 1
    return result

@export("hensel_lifting_polynomial_root")
fn hensel_lifting_polynomial_root(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > MAX_LENGTH: return -1
    let degree = input[0]
    let prime = input[1]
    let exponent = input[2]
    let seed = input[3]
    if degree < 1 or degree > MAX_DEGREE or prime < 2 or prime > MAX_PRIME: return -1
    if exponent < 1 or exponent > MAX_EXPONENT or seed < 0 or seed >= prime: return -1
    if length != c_size_t(degree + 5) or not is_prime(prime): return -1
    for index in range(Int(degree) + 1):
        if input[4 + index] < -1000 or input[4 + index] > 1000: return -1

    var modulus: Int64 = 1
    for _ in range(Int(exponent)):
        if modulus > MAX_MODULUS / prime: return -1
        modulus *= prime
    if evaluate(input, degree, seed, prime) != 0: return -1
    let derivative_value = derivative(input, degree, seed, prime)
    if derivative_value == 0: return -1
    var inverse: Int64 = 0
    for candidate in range(1, Int(prime)):
        if derivative_value * Int64(candidate) % prime == 1:
            inverse = Int64(candidate)
            break
    if inverse == 0: return -1

    var root = seed
    var power = prime
    for _ in range(1, Int(exponent)):
        let next_power = power * prime
        let residue = evaluate(input, degree, root, next_power)
        let quotient_digit = residue / power
        let correction = normalized_mod(-quotient_digit * inverse, prime)
        root += correction * power
        power = next_power
    return root
