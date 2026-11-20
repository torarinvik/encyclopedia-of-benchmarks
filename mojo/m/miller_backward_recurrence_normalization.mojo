from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MILLER_MODULUS = Int64(998244353)
alias MILLER_MAX_INPUT = 35

fn miller_mod_pow(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % MILLER_MODULUS
        base = base * base % MILLER_MODULUS
        exponent = exponent >> 1
    return result

fn miller_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("miller_backward_recurrence_normalization")
fn miller_backward_recurrence_normalization(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > MILLER_MAX_INPUT:
        return -1
    let levels_value = input[0]
    if levels_value < 1 or levels_value > 8: return -1
    let levels = Int(levels_value)
    if length != c_size_t(4 * levels + 2): return -1
    for index in range(1, Int(length)):
        if input[index] < 0 or input[index] >= MILLER_MODULUS: return -1
    for level in range(1, levels + 1):
        if input[3 * level] == 0: return -1

    var trial: InlineArray[Int64, 10] = InlineArray[Int64, 10](fill=0)
    trial[levels] = 1
    trial[levels + 1] = 0
    var level = levels
    while level > 0:
        let a_value = input[3 * level - 2]
        let b_value = input[3 * level - 1]
        let c_value = input[3 * level]
        let positive = b_value * trial[level] % MILLER_MODULUS
        let negative = a_value * trial[level + 1] % MILLER_MODULUS
        let numerator = (positive + MILLER_MODULUS - negative) % MILLER_MODULUS
        trial[level - 1] = numerator * miller_mod_pow(c_value, MILLER_MODULUS - 2) % MILLER_MODULUS
        level = level - 1

    let lambda_start = 3 * levels + 1
    var normalizer: Int64 = 0
    for index in range(levels + 1):
        normalizer = (normalizer + input[lambda_start + index] * trial[index]) % MILLER_MODULUS
    if normalizer == 0: return -1
    let scale = miller_mod_pow(normalizer, MILLER_MODULUS - 2)
    let required = 8 * (levels + 2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2

    miller_store_le(output, 0, levels_value)
    for index in range(levels + 1):
        miller_store_le(output, 8 * (index + 1), trial[index] * scale % MILLER_MODULUS)
    return Int64(required)
