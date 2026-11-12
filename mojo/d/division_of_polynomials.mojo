from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime POLY_MODULUS: Int64 = 998244353
comptime POLY_MAX_N = 64
comptime POLY_MAX_INPUT = 131
comptime POLY_MAX_OUTPUT_BYTES = 536

fn poly_power_mod(base_input: Int64, exponent_input: Int64) -> Int64:
    var base = base_input
    var exponent = exponent_input
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = result * base % POLY_MODULUS
        base = base * base % POLY_MODULUS
        exponent >>= 1
    return result

fn poly_trim(polynomial: InlineArray[Int64, POLY_MAX_N], length_input: Int) -> Int:
    var length = length_input
    while length > 0 and polynomial[length - 1] == 0:
        length -= 1
    return length

fn poly_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("division_of_polynomials")
fn division_of_polynomials(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > POLY_MAX_INPUT:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > POLY_MAX_N or m_value < 1 or m_value > POLY_MAX_N:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if Int(length) != 2 + n + m:
        return -1

    var work = InlineArray[Int64, POLY_MAX_N]()
    var quotient = InlineArray[Int64, POLY_MAX_N]()
    for i in range(n):
        work[i] = input[2 + i]
        if work[i] < 0 or work[i] >= POLY_MODULUS:
            return -1
    for i in range(m):
        let coefficient = input[2 + n + i]
        if coefficient < 0 or coefficient >= POLY_MODULUS:
            return -1
    if work[n - 1] == 0 or input[2 + n + m - 1] == 0:
        return -1

    var quotient_bound = 0
    if n >= m:
        quotient_bound = n - m + 1
        let inverse_leading = poly_power_mod(input[2 + n + m - 1], POLY_MODULUS - 2)
        var shift_plus_one = quotient_bound
        while shift_plus_one > 0:
            let shift = shift_plus_one - 1
            let factor = work[shift + m - 1] * inverse_leading % POLY_MODULUS
            quotient[shift] = factor
            for j in range(m):
                var value = (work[shift + j] - factor * input[2 + n + j]) % POLY_MODULUS
                if value < 0:
                    value += POLY_MODULUS
                work[shift + j] = value
            shift_plus_one -= 1

    let quotient_length = poly_trim(quotient, quotient_bound)
    let remainder_bound = n if n < m else m
    let remainder_length = poly_trim(work, remainder_bound)
    let output_bytes = 8 * (2 + quotient_length + remainder_length)
    if output_bytes > POLY_MAX_OUTPUT_BYTES:
        return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < output_bytes:
        return -2

    poly_store_le(output, 0, Int64(quotient_length))
    poly_store_le(output, 8, Int64(remainder_length))
    var offset = 16
    for i in range(quotient_length):
        poly_store_le(output, offset, quotient[i])
        offset += 8
    for i in range(remainder_length):
        poly_store_le(output, offset, work[i])
        offset += 8
    return Int64(output_bytes)
