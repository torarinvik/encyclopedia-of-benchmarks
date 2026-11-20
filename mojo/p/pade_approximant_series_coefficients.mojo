from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MODULUS = Int64(998244353)
alias MAX_INPUT_LENGTH = 12

fn mod_pow(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % MODULUS
        base = base * base % MODULUS
        exponent = exponent >> 1
    return result

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("pade_approximant_series_coefficients")
fn pade_approximant_series_coefficients(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > MAX_INPUT_LENGTH: return -1
    let p_value = input[0]
    let q_value = input[1]
    if q_value < 1 or p_value < q_value or p_value > 4 or q_value > 4 or length != p_value + q_value + 3: return -1
    let p = Int(p_value)
    let q = Int(q_value)
    var coefficients = InlineArray[UInt32, 9](fill=0)
    for index in range(0, p + q + 1):
        if input[index + 2] < 0 or input[index + 2] >= MODULUS: return -1
        coefficients[index] = UInt32(input[index + 2])
    let required = 8 * (p + q + 4)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2

    var matrix = InlineArray[UInt32, 20](fill=0)
    for row in range(0, q):
        let m = p + 1 + row
        for col in range(0, q): matrix[row * 5 + col] = coefficients[m - col - 1]
        matrix[row * 5 + q] = UInt32((MODULUS - Int64(coefficients[m])) % MODULUS)
    for col in range(0, q):
        var pivot = col
        while pivot < q and matrix[pivot * 5 + col] == 0: pivot += 1
        if pivot == q: return -3
        if pivot != col:
            for j in range(0, q + 1):
                let temporary = matrix[col * 5 + j]
                matrix[col * 5 + j] = matrix[pivot * 5 + j]
                matrix[pivot * 5 + j] = temporary
        let inverse = mod_pow(Int64(matrix[col * 5 + col]), MODULUS - 2)
        for j in range(col, q + 1):
            matrix[col * 5 + j] = UInt32(Int64(matrix[col * 5 + j]) * inverse % MODULUS)
        for row in range(0, q):
            if row == col: continue
            let factor = Int64(matrix[row * 5 + col])
            for j in range(col, q + 1):
                let product = factor * Int64(matrix[col * 5 + j]) % MODULUS
                var difference = Int64(matrix[row * 5 + j]) - product
                if difference < 0: difference += MODULUS
                matrix[row * 5 + j] = UInt32(difference)

    store_i64_le(output, 0, p_value)
    store_i64_le(output, 8, q_value)
    var offset = 16
    for m in range(0, p + 1):
        var value = UInt64(coefficients[m])
        let last = min(m, q)
        for j in range(1, last + 1):
            value = (value + UInt64(coefficients[m - j]) * UInt64(matrix[(j - 1) * 5 + q])) % UInt64(MODULUS)
        store_i64_le(output, offset, Int64(value))
        offset += 8
    store_i64_le(output, offset, 1)
    offset += 8
    for j in range(0, q):
        store_i64_le(output, offset, Int64(matrix[j * 5 + q]))
        offset += 8
    return Int64(required)
