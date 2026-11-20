from std.ffi import c_size_t
from std.collections import InlineArray
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_TERMS = 8
alias MAX_INPUT_LENGTH = 19
alias MODULUS: Int64 = 998244353

fn lentz_norm(value_input: Int64) -> Int64:
    var value = value_input % MODULUS
    if value < 0: value += MODULUS
    return value

fn lentz_power(base_input: Int64, exponent_input: Int64) -> Int64:
    var base = lentz_norm(base_input)
    var exponent = exponent_input
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    return result

fn lentz_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8): output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("lentz_continued_fraction_convergents")
fn lentz_continued_fraction_convergents(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1
            or length > c_size_t(MAX_INPUT_LENGTH): return -1
    let count_value = input[0]
    if count_value < 1 or count_value > MAX_TERMS: return -1
    let count = Int(count_value)
    if length != c_size_t(2 + 2 * count): return -1
    for i in range(1, Int(length)):
        if input[i] < 0 or input[i] >= MODULUS: return -1
    var value = input[1]
    if value == 0: return -1
    var c_ratio = value
    var d_ratio: Int64 = 0
    var trace = InlineArray[Int64, 10](fill=0)
    trace[0] = value
    for index in range(count):
        let numerator = input[2 + 2 * index]
        let denominator = input[3 + 2 * index]
        let d_denominator = lentz_norm(denominator + numerator * d_ratio)
        if d_denominator == 0 or c_ratio == 0: return -1
        let c_value = lentz_norm(denominator + numerator * lentz_power(c_ratio, MODULUS - 2))
        if c_value == 0: return -1
        d_ratio = lentz_power(d_denominator, MODULUS - 2)
        value = value * c_value % MODULUS * d_ratio % MODULUS
        c_ratio = c_value
        trace[index + 1] = value

    let output_bytes = 8 * (count + 2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    lentz_store(output, 0, Int64(count + 1))
    for i in range(count + 1): lentz_store(output, 8 * (i + 1), trace[i])
    return Int64(output_bytes)
