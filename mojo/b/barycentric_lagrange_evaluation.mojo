from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias BARY_MODULUS = Int64(998244353)
alias BARY_MAX_NODES = 8
alias BARY_MAX_INPUT = 19

fn bary_mod_pow(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % BARY_MODULUS
        base = base * base % BARY_MODULUS
        exponent = exponent >> 1
    return result

@export("barycentric_lagrange_evaluation")
fn barycentric_lagrange_evaluation(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > BARY_MAX_INPUT:
        return -1
    let count_value = input[0]
    if count_value < 1 or count_value > BARY_MAX_NODES: return -1
    let count = Int(count_value)
    if length != c_size_t(2 * count + 2): return -1
    for index in range(1, Int(length)):
        if input[index] < 0 or input[index] >= BARY_MODULUS: return -1
    for left in range(count):
        for right in range(left):
            if input[1 + left] == input[1 + right]: return -1

    var weights = InlineArray[Int64, 8](fill=0)
    for index in range(count):
        var product: Int64 = 1
        let node = input[1 + index]
        for other in range(count):
            if other == index: continue
            let difference = (node - input[1 + other] + BARY_MODULUS) % BARY_MODULUS
            product = product * difference % BARY_MODULUS
        weights[index] = bary_mod_pow(product, BARY_MODULUS - 2)

    let ordinate_start = 1 + count
    let query = input[2 * count + 1]
    for index in range(count):
        if query == input[1 + index]: return input[ordinate_start + index]
    var numerator: Int64 = 0
    var denominator: Int64 = 0
    for index in range(count):
        let difference = (query - input[1 + index] + BARY_MODULUS) % BARY_MODULUS
        let term = weights[index] * bary_mod_pow(difference, BARY_MODULUS - 2) % BARY_MODULUS
        numerator = (numerator + term * input[ordinate_start + index]) % BARY_MODULUS
        denominator = (denominator + term) % BARY_MODULUS
    if denominator == 0: return -1
    return numerator * bary_mod_pow(denominator, BARY_MODULUS - 2) % BARY_MODULUS
