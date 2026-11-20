from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias FORNBERG_MODULUS = Int64(998244353)
alias FORNBERG_MAX_NODES = 8
alias FORNBERG_MAX_INPUT = 12

fn fornberg_mod_norm(value: Int64) -> Int64:
    let reduced = value % FORNBERG_MODULUS
    return reduced + FORNBERG_MODULUS if reduced < 0 else reduced

fn fornberg_mod_pow(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % FORNBERG_MODULUS
        base = base * base % FORNBERG_MODULUS
        exponent = exponent >> 1
    return result

fn fornberg_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
                         value: Int64) -> None:
    let bits = value.bitcast[UInt64]()
    for byte in range(8): output[offset + byte] = ((bits >> (8 * byte)) & 255).to[UInt8]()

@export("fornberg_finite_difference_weights")
fn fornberg_finite_difference_weights(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > FORNBERG_MAX_INPUT:
        return -1
    let n_value = input[0]
    let order = input[1]
    let target = input[2]
    if n_value < 1 or n_value > FORNBERG_MAX_NODES or order < 0 or order > 3
        or order >= n_value or length != c_size_t(n_value + 3): return -1
    let n = Int(n_value)
    if target < 0 or target >= FORNBERG_MODULUS: return -1
    for index in range(n):
        let node = input[3 + index]
        if node < 0 or node >= FORNBERG_MODULUS: return -1
        for previous in range(index):
            if node == input[3 + previous]: return -1

    var table = InlineArray[Int64, 32](fill=0)
    table[0] = 1
    var previous_product: Int64 = 1
    for new_index in range(1, n):
        var old_last = InlineArray[Int64, 4](fill=0)
        for derivative in range(4): old_last[derivative] = table[4 * (new_index - 1) + derivative]
        var product: Int64 = 1
        let node = input[3 + new_index]
        let factor = fornberg_mod_norm(node - target)
        let max_derivative = min(new_index, Int(order))
        for old_index in range(new_index):
            let difference = fornberg_mod_norm(node - input[3 + old_index])
            product = product * difference % FORNBERG_MODULUS
            let inverse_difference = fornberg_mod_pow(difference, FORNBERG_MODULUS - 2)
            var derivative = max_derivative
            while derivative >= 0:
                let lower: Int64 = if derivative == 0: 0 else: table[4 * old_index + derivative - 1]
                let numerator = fornberg_mod_norm(
                    factor * table[4 * old_index + derivative] - Int64(derivative) * lower)
                table[4 * old_index + derivative] = numerator * inverse_difference % FORNBERG_MODULUS
                derivative -= 1
        let product_inverse = fornberg_mod_pow(product, FORNBERG_MODULUS - 2)
        let last_factor = fornberg_mod_norm(input[2 + new_index] - target)
        for derivative in range(max_derivative + 1):
            let lower: Int64 = if derivative == 0: 0 else: old_last[derivative - 1]
            let numerator = fornberg_mod_norm(
                Int64(derivative) * lower - last_factor * old_last[derivative])
            table[4 * new_index + derivative] = previous_product * product_inverse
                % FORNBERG_MODULUS * numerator % FORNBERG_MODULUS
        previous_product = product

    let required = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    fornberg_store_i64_le(output, 0, n_value)
    for index in range(n):
        fornberg_store_i64_le(output, 8 * (index + 1), table[4 * index + Int(order)])
    return Int64(required)
