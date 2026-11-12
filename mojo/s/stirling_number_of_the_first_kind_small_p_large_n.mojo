from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MAX_N: Int64 = 1_000_000_000_000_000_000
const MAX_T = 8
const MAX_K = 8
const WIDTH = 9

fn is_prime(value: Int64) -> Bool:
    if value < 2: return False
    var divisor: Int64 = 2
    while divisor <= value // divisor:
        if value % divisor == 0: return False
        divisor += 1
    return True

fn stirling_value(n: Int64, k: Int, modulus: Int64) -> Int64:
    let quotient = n // modulus
    let remainder = n % modulus
    if quotient > Int64(k): return 0
    let target = k - Int(quotient)
    var coefficients = InlineArray[Int64, WIDTH](fill=0)
    coefficients[0] = 1
    for residue in range(Int(remainder)):
        for degree in range(target, 0, -1):
            coefficients[degree] = (coefficients[degree - 1] - Int64(residue) * coefficients[degree]) % modulus
            if coefficients[degree] < 0:
                coefficients[degree] += modulus
        coefficients[0] = (-Int64(residue) * coefficients[0]) % modulus
        if coefficients[0] < 0:
            coefficients[0] += modulus
    let coefficient = coefficients[target]
    if quotient % 2 == 0 or coefficient == 0: return coefficient
    return modulus - coefficient

@export("stirling_number_of_the_first_kind_small_p_large_n")
fn stirling_number_of_the_first_kind_small_p_large_n(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(4) or length > c_size_t(18):
        return -1
    let count_value = input[0]
    let modulus = input[1]
    if count_value < 1 or count_value > MAX_T: return -1
    let count = Int(count_value)
    if length != c_size_t(2 + 2 * count): return -1
    if modulus < 11 or modulus > 97 or not is_prime(modulus): return -1

    var result: Int64 = 0
    for case_index in range(count):
        let n = input[2 + 2 * case_index]
        let k_value = input[3 + 2 * case_index]
        if n < 0 or n > MAX_N or k_value < 0 or k_value > MAX_K or k_value > n: return -1
        let value = stirling_value(n, Int(k_value), modulus)
        let next = Int64(case_index + 1)
        result = (result + next * next * value) % modulus
    return result
