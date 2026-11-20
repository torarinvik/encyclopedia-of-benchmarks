from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MODULUS = Int64(998244353)
alias MAX_INPUT_LENGTH = 11

fn mod_pow(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % MODULUS
        base = base * base % MODULUS
        exponent = exponent >> 1
    return result

fn next_numerator(coefficient: Int64, rho: Int64) -> Int64:
    return coefficient * ((rho + 1) % MODULUS) % MODULUS

fn divisors_are_nonzero(input: UnsafePointer[Int64, ImmutAnyOrigin], count: Int) -> Bool:
    var rho: Int64 = 0
    for index in range(1, count):
        let top = next_numerator(input[index + 1], rho)
        let denominator = (1 + MODULUS - top) % MODULUS
        if denominator == 0: return False
        rho = top * mod_pow(denominator, MODULUS - 2) % MODULUS
    return True

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("continued_fraction_forward_series_recurrence")
fn continued_fraction_forward_series_recurrence(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT_LENGTH:
        return -1
    let count_value = input[0]
    if count_value < 2 or count_value > 9: return -1
    let count = Int(count_value)
    if length != c_size_t(count + 1): return -1
    for index in range(1, count + 1):
        if input[index] < 0 or input[index] >= MODULUS: return -1
    if not divisors_are_nonzero(input, count): return -1
    let required = 8 * (count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2

    store_i64_le(output, 0, count_value)
    var rho: Int64 = 0
    var term = input[1]
    var sum = term
    store_i64_le(output, 8, sum)
    for index in range(1, count):
        let top = next_numerator(input[index + 1], rho)
        let denominator = (1 + MODULUS - top) % MODULUS
        rho = top * mod_pow(denominator, MODULUS - 2) % MODULUS
        term = rho * term % MODULUS
        sum = (sum + term) % MODULUS
        store_i64_le(output, 8 * (index + 1), sum)
    return Int64(required)
