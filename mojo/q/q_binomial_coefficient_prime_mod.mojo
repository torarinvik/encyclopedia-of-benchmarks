from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MAX_T = 16
const MAX_N = 16
const MAX_MODULUS = 31
const MAX_PARSEABLE_INPUT_LENGTH = 36

fn is_prime(value: Int64) -> Bool:
    if value < 2: return False
    var divisor: Int64 = 2
    while divisor <= value // divisor:
        if value % divisor == 0: return False
        divisor += 1
    return True

fn modular_power(base_value: Int64, exponent_value: Int64,
                 modulus: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % modulus
        base = base * base % modulus
        exponent = exponent >> 1
    return result

@export("q_binomial_coefficient_prime_mod")
fn q_binomial_coefficient_prime_mod(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(3) or length > c_size_t(MAX_PARSEABLE_INPUT_LENGTH):
        return -1
    let count_value = input[0]
    let modulus = input[1]
    let q_value = input[2]
    if count_value < 1 or count_value > Int64(MAX_T) or modulus < 2 or modulus > Int64(MAX_MODULUS) or not is_prime(modulus) or q_value < 0 or q_value >= modulus:
        return -1
    let count = Int(count_value)
    if length != c_size_t(3 + 2 * count): return -1

    var max_n = 0
    for query in range(count):
        let n_value = input[3 + 2 * query]
        let k_value = input[4 + 2 * query]
        if n_value < 0 or n_value > MAX_N or k_value < 0 or k_value > MAX_N or n_value >= modulus or k_value >= modulus:
            return -1
        if Int(n_value) > max_n: max_n = Int(n_value)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(count):
        return -2

    var table = InlineArray[Int64, (MAX_N + 1) * (MAX_N + 1)](fill=0)
    table[0] = 1
    for n in range(1, max_n + 1):
        table[n * 17] = 1
        for k in range(1, n + 1):
            var previous_same: Int64 = 0
            if k < n: previous_same = table[(n - 1) * 17 + k]
            let weight = modular_power(q_value, Int64(n - k), modulus)
            table[n * 17 + k] =
                (previous_same + weight * table[(n - 1) * 17 + k - 1]) % modulus

    for query in range(count):
        let n = Int(input[3 + 2 * query])
        let k = Int(input[4 + 2 * query])
        var value: Int64 = 0
        if k <= n: value = table[n * 17 + k]
        output[query] = UInt8(value)
    return Int64(count)
