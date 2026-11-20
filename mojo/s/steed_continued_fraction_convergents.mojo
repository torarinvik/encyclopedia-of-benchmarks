from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MODULUS = Int64(998244353)
alias MAX_INPUT_LENGTH = 19

fn mod_pow(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % MODULUS
        base = base * base % MODULUS
        exponent = exponent >> 1
    return result

fn divisors_are_nonzero(input: UnsafePointer[Int64, ImmutAnyOrigin], levels: Int) -> Bool:
    if input[2] == 0: return False
    var d_value = mod_pow(input[2], MODULUS - 2)
    for level in range(2, levels + 1):
        let denominator = (d_value * input[2 * level + 1] + input[2 * level]) % MODULUS
        if denominator == 0: return False
        d_value = mod_pow(denominator, MODULUS - 2)
    return True

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("steed_continued_fraction_convergents")
fn steed_continued_fraction_convergents(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > MAX_INPUT_LENGTH:
        return -1
    let levels_value = input[0]
    if levels_value < 1 or levels_value > 8: return -1
    let levels = Int(levels_value)
    if length != c_size_t(2 + 2 * levels): return -1
    for index in range(1, Int(length)):
        if input[index] < 0 or input[index] >= MODULUS: return -1
    if not divisors_are_nonzero(input, levels): return -1

    let required = 8 * (levels + 2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    store_i64_le(output, 0, levels_value + 1)
    var current = input[1]
    store_i64_le(output, 8, current)
    var d_value = mod_pow(input[2], MODULUS - 2)
    var delta = input[3] * d_value % MODULUS
    current = (current + delta) % MODULUS
    store_i64_le(output, 16, current)
    for level in range(2, levels + 1):
        let b_value = input[2 * level]
        let a_value = input[2 * level + 1]
        let denominator = (d_value * a_value + b_value) % MODULUS
        d_value = mod_pow(denominator, MODULUS - 2)
        let factor = (b_value * d_value + MODULUS - 1) % MODULUS
        delta = factor * delta % MODULUS
        current = (current + delta) % MODULUS
        store_i64_le(output, 8 * (level + 1), current)
    return Int64(required)
