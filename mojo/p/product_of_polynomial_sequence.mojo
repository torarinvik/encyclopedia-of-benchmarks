from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime PRODUCT_MODULUS: Int64 = 998244353
comptime PRODUCT_MAX_FACTORS = 6
comptime PRODUCT_MAX_COEFFICIENTS = 25
comptime PRODUCT_MAX_INPUT = 38

fn product_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("product_of_polynomial_sequence")
fn product_of_polynomial_sequence(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > PRODUCT_MAX_INPUT:
        return -1
    if input[0] < 0 or input[0] > PRODUCT_MAX_FACTORS:
        return -1
    let count = Int(input[0])
    var polynomials = InlineArray[Int64, PRODUCT_MAX_FACTORS * PRODUCT_MAX_COEFFICIENTS]()
    var lengths = InlineArray[Int, PRODUCT_MAX_FACTORS]()
    var cursor = 1
    var degree_sum = 0
    for p in range(count):
        if cursor >= Int(length) or input[cursor] < 0 or input[cursor] > 4:
            return -1
        let degree = Int(input[cursor])
        cursor += 1
        if cursor + degree + 1 > Int(length):
            return -1
        for i in range(degree + 1):
            let coefficient = input[cursor + i]
            if coefficient < 0 or coefficient >= PRODUCT_MODULUS:
                return -1
            polynomials[p * PRODUCT_MAX_COEFFICIENTS + i] = coefficient
        if polynomials[p * PRODUCT_MAX_COEFFICIENTS + degree] == 0:
            return -1
        lengths[p] = degree + 1
        degree_sum += degree
        cursor += degree + 1
    if cursor != Int(length):
        return -1

    let result_length = degree_sum + 1
    let bytes = 8 * result_length
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2
    if count == 0:
        product_store_le(output, 0, 1)
        return 8

    var scratch = InlineArray[Int64, PRODUCT_MAX_COEFFICIENTS]()
    var active = count
    while active > 1:
        var next_count = 0
        var i = 0
        while i < active:
            let destination = next_count * PRODUCT_MAX_COEFFICIENTS
            if i + 1 == active:
                let source = i * PRODUCT_MAX_COEFFICIENTS
                for j in range(lengths[i]):
                    polynomials[destination + j] = polynomials[source + j]
                lengths[next_count] = lengths[i]
            else:
                let left_start = i * PRODUCT_MAX_COEFFICIENTS
                let right_start = (i + 1) * PRODUCT_MAX_COEFFICIENTS
                let product_length = lengths[i] + lengths[i + 1] - 1
                for j in range(product_length):
                    scratch[j] = 0
                for a in range(lengths[i]):
                    for b in range(lengths[i + 1]):
                        let slot = a + b
                        scratch[slot] = (scratch[slot] +
                            polynomials[left_start + a] * polynomials[right_start + b]) % PRODUCT_MODULUS
                for j in range(product_length):
                    polynomials[destination + j] = scratch[j]
                lengths[next_count] = product_length
            next_count += 1
            i += 2
        active = next_count
    for i in range(result_length):
        product_store_le(output, 8 * i, polynomials[i])
    return Int64(bytes)
