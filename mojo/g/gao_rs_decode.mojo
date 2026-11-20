from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias GAO_MAX_N = 7
alias GAO_MAX_K = 3
alias GAO_POLY = 8
alias GAO_MAX_INPUT_LENGTH = 11

fn gao_mod7(value: Int64) -> Int64:
    let remainder = value % 7
    return remainder + 7 if remainder < 0 else remainder

fn gao_inverse7(value: Int64) -> Int64:
    if value == 1: return 1
    if value == 2: return 4
    if value == 3: return 5
    if value == 4: return 2
    if value == 5: return 3
    if value == 6: return 6
    return 0

fn gao_poly_zero(polynomial: InlineArray[Int64, GAO_POLY]) -> Bool:
    for degree in range(GAO_POLY):
        if polynomial[degree] != 0: return False
    return True

fn gao_poly_degree(polynomial: InlineArray[Int64, GAO_POLY]) -> Int:
    for degree in range(GAO_POLY - 1, -1, -1):
        if polynomial[degree] != 0: return degree
    return 0

fn gao_multiply_linear(inout polynomial: InlineArray[Int64, GAO_POLY], root: Int64):
    var product = InlineArray[Int64, GAO_POLY]()
    for degree in range(GAO_POLY):
        product[degree] = gao_mod7(product[degree] - root * polynomial[degree])
        if degree + 1 < GAO_POLY:
            product[degree + 1] = gao_mod7(product[degree + 1] + polynomial[degree])
    polynomial = product

fn gao_interpolate(n: Int, values: InlineArray[Int64, GAO_MAX_N]) -> InlineArray[Int64, GAO_POLY]:
    var result = InlineArray[Int64, GAO_POLY]()
    for i in range(n):
        var basis = InlineArray[Int64, GAO_POLY]()
        basis[0] = 1
        var denominator: Int64 = 1
        for j in range(n):
            if j == i: continue
            gao_multiply_linear(inout basis, Int64(j))
            denominator = gao_mod7(denominator * (Int64(i) - Int64(j)))
        let scale = gao_mod7(values[i] * gao_inverse7(denominator))
        for degree in range(GAO_POLY):
            result[degree] = gao_mod7(result[degree] + scale * basis[degree])
    return result

fn gao_vanishing_polynomial(n: Int) -> InlineArray[Int64, GAO_POLY]:
    var result = InlineArray[Int64, GAO_POLY]()
    result[0] = 1
    for point in range(n):
        gao_multiply_linear(inout result, Int64(point))
    return result

fn gao_divide(numerator: InlineArray[Int64, GAO_POLY],
    denominator: InlineArray[Int64, GAO_POLY],
    inout quotient: InlineArray[Int64, GAO_POLY],
    inout remainder: InlineArray[Int64, GAO_POLY]) -> Bool:
    if gao_poly_zero(denominator): return False
    quotient = InlineArray[Int64, GAO_POLY]()
    remainder = numerator
    let denominator_degree = gao_poly_degree(denominator)
    var remainder_degree = gao_poly_degree(remainder)
    let inverse_lead = gao_inverse7(denominator[denominator_degree])
    while not gao_poly_zero(remainder) and remainder_degree >= denominator_degree:
        let shift = remainder_degree - denominator_degree
        let factor = gao_mod7(remainder[remainder_degree] * inverse_lead)
        quotient[shift] = gao_mod7(quotient[shift] + factor)
        for degree in range(denominator_degree + 1):
            remainder[shift + degree] = gao_mod7(
                remainder[shift + degree] - factor * denominator[degree])
        remainder_degree = gao_poly_degree(remainder)
    return True

fn gao_multiply_poly(left: InlineArray[Int64, GAO_POLY],
    right: InlineArray[Int64, GAO_POLY]) -> InlineArray[Int64, GAO_POLY]:
    var product = InlineArray[Int64, GAO_POLY]()
    for i in range(GAO_POLY):
        for j in range(GAO_POLY):
            if i + j >= GAO_POLY: break
            product[i + j] = gao_mod7(product[i + j] + left[i] * right[j])
    return product

fn gao_subtract_poly(left: InlineArray[Int64, GAO_POLY],
    right: InlineArray[Int64, GAO_POLY]) -> InlineArray[Int64, GAO_POLY]:
    var result = InlineArray[Int64, GAO_POLY]()
    for degree in range(GAO_POLY):
        result[degree] = gao_mod7(left[degree] - right[degree])
    return result

fn gao_decode(n: Int, k: Int, errors: Int,
    received: InlineArray[Int64, GAO_MAX_N]) -> Int64:
    let interpolant = gao_interpolate(n, received)
    if gao_poly_zero(interpolant): return 1

    var r0 = gao_vanishing_polynomial(n)
    var r1 = interpolant
    var v0 = InlineArray[Int64, GAO_POLY]()
    var v1 = InlineArray[Int64, GAO_POLY]()
    v1[0] = 1
    var candidate_numerator = InlineArray[Int64, GAO_POLY]()
    var candidate_denominator = InlineArray[Int64, GAO_POLY]()
    var found = False
    while not gao_poly_zero(r1):
        if 2 * gao_poly_degree(r1) < n + k:
            candidate_numerator = r1
            candidate_denominator = v1
            found = True
            break
        var quotient = InlineArray[Int64, GAO_POLY]()
        var remainder = InlineArray[Int64, GAO_POLY]()
        if not gao_divide(r0, r1, inout quotient, inout remainder): return 0
        if gao_poly_zero(remainder): break
        let v2 = gao_subtract_poly(v0, gao_multiply_poly(quotient, v1))
        r0 = r1
        r1 = remainder
        v0 = v1
        v1 = v2
    if not found or gao_poly_zero(candidate_denominator): return 0

    var coefficients = InlineArray[Int64, GAO_POLY]()
    var division_remainder = InlineArray[Int64, GAO_POLY]()
    if not gao_divide(candidate_numerator, candidate_denominator,
        inout coefficients, inout division_remainder): return 0
    if not gao_poly_zero(division_remainder) or gao_poly_degree(coefficients) >= k:
        return 0
    var mismatches = 0
    for x in range(n):
        var value: Int64 = 0
        for degree in range(k, 0, -1):
            value = (value * Int64(x) + coefficients[degree - 1]) % 7
        if value != received[x]: mismatches += 1
    if mismatches > errors: return 0

    var result: Int64 = 1
    var place: Int64 = 1
    for degree in range(k):
        result += coefficients[degree] * place
        place *= 7
    return result

@export("gao_rs_decode")
fn gao_rs_decode(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > GAO_MAX_INPUT_LENGTH:
        return -1
    let n_value = input[0]
    let k_value = input[1]
    let t_value = input[2]
    if n_value < 2 or n_value > GAO_MAX_N or k_value < 1 or k_value > GAO_MAX_K or
        k_value > n_value or t_value < 0 or t_value > 2 or
        2 * t_value > n_value - k_value:
        return -1
    let n = Int(n_value)
    let k = Int(k_value)
    let errors = Int(t_value)
    if length != c_size_t(3 + n): return -1
    var received = InlineArray[Int64, GAO_MAX_N]()
    for index in range(n):
        let symbol = input[3 + index]
        if symbol < 0 or symbol >= 7: return -1
        received[index] = symbol
    return gao_decode(n, k, errors, received)
