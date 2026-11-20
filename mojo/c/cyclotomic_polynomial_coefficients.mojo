from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias CYCLOTOMIC_MAX_N = 32
alias CYCLOTOMIC_MAX_INPUT = 2

fn cyclotomic_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
                           value: Int64) -> None:
    let bits = value.bitcast[UInt64]()
    for byte in range(8): output[offset + byte] = ((bits >> (8 * byte)) & 255).to[UInt8]()

@export("cyclotomic_polynomial_coefficients")
fn cyclotomic_polynomial_coefficients(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0
        or length > CYCLOTOMIC_MAX_INPUT: return -1
    let n_value = input[0]
    if n_value < 1 or n_value > CYCLOTOMIC_MAX_N or length != 1: return -1
    let n = Int(n_value)

    var polynomials = InlineArray[Int64, 1089](fill=0)
    var degrees = InlineArray[Int64, 33](fill=0)
    polynomials[33] = -1
    polynomials[34] = 1
    degrees[1] = 1
    for k in range(2, n + 1):
        var divisor = InlineArray[Int64, 33](fill=0)
        divisor[0] = 1
        var divisor_degree = 0
        for d in range(1, k):
            if k % d != 0: continue
            var product = InlineArray[Int64, 33](fill=0)
            for i in range(divisor_degree + 1):
                for j in range(Int(degrees[d]) + 1):
                    product[i + j] += divisor[i] * polynomials[d * 33 + j]
            divisor_degree += Int(degrees[d])
            for i in range(divisor_degree + 1): divisor[i] = product[i]

        var remainder = InlineArray[Int64, 33](fill=0)
        remainder[0] = -1
        remainder[k] = 1
        let quotient_degree = k - divisor_degree
        degrees[k] = Int64(quotient_degree)
        for offset in range(quotient_degree + 1):
            let q = quotient_degree - offset
            let leading = remainder[divisor_degree + q]
            polynomials[k * 33 + q] = leading
            for j in range(divisor_degree + 1):
                remainder[q + j] -= leading * divisor[j]

    let coefficient_count = Int(degrees[n]) + 1
    let required = 8 * coefficient_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    for index in range(coefficient_count):
        cyclotomic_store_i64_le(output, 8 * index, polynomials[n * 33 + index])
    return Int64(required)
