from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MODULUS = 998_244_353
const MAX_N = 32

fn modular_power(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % MODULUS
        base = base * base % MODULUS
        exponent = exponent >> 1
    return result

@export("bernoulli_number")
fn bernoulli_number(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != c_size_t(1): return -1
    let n_value = input[0]
    if n_value < 0 or n_value > MAX_N: return -1
    let n = Int(n_value)
    let output_bytes = 4 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2

    var inverse = InlineArray[Int64, MAX_N + 2](fill=0)
    var bernoulli = InlineArray[Int64, MAX_N + 1](fill=0)
    inverse[1] = 1
    bernoulli[0] = 1
    for i in range(2, n + 2):
        inverse[i] = modular_power(Int64(i), MODULUS - 2)

    for m in range(1, n + 1):
        var choose: Int64 = 1
        var total: Int64 = 0
        for k in range(m):
            total = (total + choose * bernoulli[k]) % MODULUS
            choose = choose * Int64(m + 1 - k) % MODULUS * inverse[k + 1] % MODULUS
        bernoulli[m] = ((MODULUS - total) % MODULUS) * inverse[m + 1] % MODULUS

    for i in range(n + 1):
        let value = UInt32(bernoulli[i])
        output[4 * i] = UInt8(value & UInt32(255))
        output[4 * i + 1] = UInt8((value >> 8) & UInt32(255))
        output[4 * i + 2] = UInt8((value >> 16) & UInt32(255))
        output[4 * i + 3] = UInt8((value >> 24) & UInt32(255))
    return Int64(output_bytes)
