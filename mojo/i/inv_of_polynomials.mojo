from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime INV_POLY_MODULUS: Int64 = 998244353
comptime INV_POLY_MAX_LENGTH = 6
comptime INV_POLY_MAX_INPUT = 14
comptime INV_POLY_CAPACITY = 16

fn inv_poly_power_mod(base_input: Int64, exponent_input: Int64) -> Int64:
    var base = base_input
    var exponent = exponent_input
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = result * base % INV_POLY_MODULUS
        base = base * base % INV_POLY_MODULUS
        exponent >>= 1
    return result

fn inv_poly_trim(polynomial: InlineArray[Int64, INV_POLY_CAPACITY], length_input: Int) -> Int:
    var length = length_input
    while length > 0 and polynomial[length - 1] == 0:
        length -= 1
    return length

fn inv_poly_divide(
    dividend: InlineArray[Int64, INV_POLY_CAPACITY], dividend_length: Int,
    divisor: InlineArray[Int64, INV_POLY_CAPACITY], divisor_length: Int,
    inout quotient: InlineArray[Int64, INV_POLY_CAPACITY], inout quotient_length: Int,
    inout remainder: InlineArray[Int64, INV_POLY_CAPACITY], inout remainder_length: Int,
):
    for i in range(INV_POLY_CAPACITY):
        quotient[i] = 0
        remainder[i] = 0
    for i in range(dividend_length):
        remainder[i] = dividend[i]
    remainder_length = inv_poly_trim(remainder, dividend_length)
    if remainder_length >= divisor_length:
        let inverse_lead = inv_poly_power_mod(divisor[divisor_length - 1], INV_POLY_MODULUS - 2)
        while remainder_length >= divisor_length:
            let shift = remainder_length - divisor_length
            let factor = remainder[remainder_length - 1] * inverse_lead % INV_POLY_MODULUS
            quotient[shift] = factor
            for j in range(divisor_length):
                var value = (remainder[shift + j] - factor * divisor[j]) % INV_POLY_MODULUS
                if value < 0:
                    value += INV_POLY_MODULUS
                remainder[shift + j] = value
            remainder_length = inv_poly_trim(remainder, remainder_length)
    quotient_bound = 0
    if dividend_length >= divisor_length:
        quotient_bound = dividend_length - divisor_length + 1
    quotient_length = inv_poly_trim(quotient, quotient_bound)

fn inv_poly_multiply(
    left: InlineArray[Int64, INV_POLY_CAPACITY], left_length: Int,
    right: InlineArray[Int64, INV_POLY_CAPACITY], right_length: Int,
    inout product: InlineArray[Int64, INV_POLY_CAPACITY], inout product_length: Int,
):
    for i in range(INV_POLY_CAPACITY):
        product[i] = 0
    if left_length == 0 or right_length == 0:
        product_length = 0
        return
    for i in range(left_length):
        for j in range(right_length):
            if i + j < INV_POLY_CAPACITY:
                product[i + j] = (product[i + j] + left[i] * right[j]) % INV_POLY_MODULUS
    var bound = left_length + right_length - 1
    if bound > INV_POLY_CAPACITY:
        bound = INV_POLY_CAPACITY
    product_length = inv_poly_trim(product, bound)

fn inv_poly_subtract(
    left: InlineArray[Int64, INV_POLY_CAPACITY], left_length: Int,
    right: InlineArray[Int64, INV_POLY_CAPACITY], right_length: Int,
    inout difference: InlineArray[Int64, INV_POLY_CAPACITY], inout difference_length: Int,
):
    let bound = left_length if left_length > right_length else right_length
    for i in range(INV_POLY_CAPACITY):
        difference[i] = 0
    for i in range(bound):
        let a = left[i] if i < left_length else 0
        let b = right[i] if i < right_length else 0
        difference[i] = (a - b + INV_POLY_MODULUS) % INV_POLY_MODULUS
    difference_length = inv_poly_trim(difference, bound)

fn inv_poly_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("inv_of_polynomials")
fn inv_of_polynomials(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > INV_POLY_MAX_INPUT:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > INV_POLY_MAX_LENGTH or m_value < 1 or m_value > INV_POLY_MAX_LENGTH:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if Int(length) != 2 + n + m:
        return -1
    var f = InlineArray[Int64, INV_POLY_CAPACITY]()
    var g = InlineArray[Int64, INV_POLY_CAPACITY]()
    for i in range(n):
        f[i] = input[2 + i]
        if f[i] < 0 or f[i] >= INV_POLY_MODULUS:
            return -1
    for i in range(m):
        g[i] = input[2 + n + i]
        if g[i] < 0 or g[i] >= INV_POLY_MODULUS:
            return -1
    if f[n - 1] == 0 or g[m - 1] == 0:
        return -1

    var inverse = InlineArray[Int64, INV_POLY_CAPACITY]()
    var inverse_length = 0
    if m > 1:
        var q_initial = InlineArray[Int64, INV_POLY_CAPACITY]()
        var initial_remainder = InlineArray[Int64, INV_POLY_CAPACITY]()
        var q_initial_length = 0
        var r1_length = 0
        inv_poly_divide(f, n, g, m, q_initial, q_initial_length, initial_remainder, r1_length)
        var r0 = g
        var r1 = initial_remainder
        var s0 = InlineArray[Int64, INV_POLY_CAPACITY]()
        var s1 = InlineArray[Int64, INV_POLY_CAPACITY]()
        var r0_length = m
        var s0_length = 0
        var s1_length = 1
        s1[0] = 1
        while r1_length > 0:
            var quotient = InlineArray[Int64, INV_POLY_CAPACITY]()
            var remainder = InlineArray[Int64, INV_POLY_CAPACITY]()
            var quotient_length = 0
            var remainder_length = 0
            inv_poly_divide(r0, r0_length, r1, r1_length,
                            quotient, quotient_length, remainder, remainder_length)
            var product = InlineArray[Int64, INV_POLY_CAPACITY]()
            var product_length = 0
            inv_poly_multiply(quotient, quotient_length, s1, s1_length, product, product_length)
            var next_s = InlineArray[Int64, INV_POLY_CAPACITY]()
            var next_s_length = 0
            inv_poly_subtract(s0, s0_length, product, product_length, next_s, next_s_length)
            r0 = r1
            r1 = remainder
            r0_length = r1_length
            r1_length = remainder_length
            s0 = s1
            s1 = next_s
            s0_length = s1_length
            s1_length = next_s_length
        if r0_length != 1:
            return -1
        let scale = inv_poly_power_mod(r0[0], INV_POLY_MODULUS - 2)
        for i in range(s0_length):
            inverse[i] = s0[i] * scale % INV_POLY_MODULUS
        inverse_length = inv_poly_trim(inverse, s0_length)
        var reduced_quotient = InlineArray[Int64, INV_POLY_CAPACITY]()
        var reduced = InlineArray[Int64, INV_POLY_CAPACITY]()
        var reduced_quotient_length = 0
        var reduced_length = 0
        inv_poly_divide(inverse, inverse_length, g, m,
                        reduced_quotient, reduced_quotient_length, reduced, reduced_length)
        inverse = reduced
        inverse_length = reduced_length

    let bytes = 8 * inverse_length
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2
    for i in range(inverse_length):
        inv_poly_store_le(output, 8 * i, inverse[i])
    return Int64(bytes)
