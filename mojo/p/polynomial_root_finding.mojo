from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime ROOT_MAX_N = 8
comptime ROOT_MAX_INPUT = 10
comptime ROOT_MAX_PRODUCT = 17
comptime ROOT_MODULUS: Int64 = 998244353
comptime ROOT_PRNG_MODULUS: Int64 = 2147483647

struct RootPolynomial(Copyable):
    var coefficients: InlineArray[Int64, ROOT_MAX_PRODUCT]
    var degree: Int

    fn __init__(out self):
        self.coefficients = InlineArray[Int64, ROOT_MAX_PRODUCT]()
        self.degree = -1

fn root_normalize(value_input: Int64) -> Int64:
    var value = value_input % ROOT_MODULUS
    if value < 0:
        value += ROOT_MODULUS
    return value

fn root_power_mod(base_input: Int64, exponent_input: Int64) -> Int64:
    var base = base_input
    var exponent = exponent_input
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = result * base % ROOT_MODULUS
        base = base * base % ROOT_MODULUS
        exponent >>= 1
    return result

fn root_trim(inout polynomial: RootPolynomial):
    while polynomial.degree >= 0 and polynomial.coefficients[polynomial.degree] == 0:
        polynomial.degree -= 1

fn root_poly_mod(value_input: RootPolynomial, divisor: RootPolynomial) -> RootPolynomial:
    var value = value_input
    if divisor.degree <= 0 or value.degree < 0:
        return RootPolynomial()
    let inverse = root_power_mod(divisor.coefficients[divisor.degree], ROOT_MODULUS - 2)
    while value.degree >= divisor.degree:
        let shift = value.degree - divisor.degree
        let factor = value.coefficients[value.degree] * inverse % ROOT_MODULUS
        for i in range(divisor.degree + 1):
            value.coefficients[shift + i] = root_normalize(
                value.coefficients[shift + i] - factor * divisor.coefficients[i]
            )
        root_trim(inout value)
    return value

fn root_multiply_mod(left: RootPolynomial, right: RootPolynomial,
    modulus_poly: RootPolynomial) -> RootPolynomial:
    if left.degree < 0 or right.degree < 0:
        return RootPolynomial()
    var product = InlineArray[Int64, ROOT_MAX_PRODUCT]()
    for i in range(left.degree + 1):
        for j in range(right.degree + 1):
            product[i + j] = (product[i + j] + left.coefficients[i] * right.coefficients[j]) % ROOT_MODULUS
    var expanded = RootPolynomial()
    expanded.degree = left.degree + right.degree
    for i in range(expanded.degree + 1):
        expanded.coefficients[i] = product[i]
    root_trim(inout expanded)
    return root_poly_mod(expanded, modulus_poly)

fn root_polynomial_power_mod(base_input: RootPolynomial, exponent_input: Int64,
    modulus_poly: RootPolynomial) -> RootPolynomial:
    var base = root_poly_mod(base_input, modulus_poly)
    var exponent = exponent_input
    var answer = RootPolynomial()
    answer.coefficients[0] = 1
    answer.degree = 0
    while exponent > 0:
        if (exponent & 1) != 0:
            answer = root_multiply_mod(answer, base, modulus_poly)
        base = root_multiply_mod(base, base, modulus_poly)
        exponent >>= 1
    return answer

fn root_polynomial_gcd(left_input: RootPolynomial, right_input: RootPolynomial) -> RootPolynomial:
    var left = left_input
    var right = right_input
    while right.degree >= 0:
        let remainder = root_poly_mod(left, right)
        left = right
        right = remainder
    if left.degree < 0:
        return left
    let inverse = root_power_mod(left.coefficients[left.degree], ROOT_MODULUS - 2)
    for i in range(left.degree + 1):
        left.coefficients[i] = left.coefficients[i] * inverse % ROOT_MODULUS
    return left

fn root_divide_exact(value_input: RootPolynomial, divisor: RootPolynomial) -> RootPolynomial:
    var value = value_input
    var quotient = RootPolynomial()
    quotient.degree = value.degree - divisor.degree
    if quotient.degree < 0:
        return quotient
    let inverse = root_power_mod(divisor.coefficients[divisor.degree], ROOT_MODULUS - 2)
    while value.degree >= divisor.degree:
        let shift = value.degree - divisor.degree
        let factor = value.coefficients[value.degree] * inverse % ROOT_MODULUS
        quotient.coefficients[shift] = factor
        for i in range(divisor.degree + 1):
            value.coefficients[shift + i] = root_normalize(
                value.coefficients[shift + i] - factor * divisor.coefficients[i]
            )
        root_trim(inout value)
    root_trim(inout quotient)
    return quotient

fn root_split_with_affine(polynomial: RootPolynomial, slope: Int64, offset: Int64,
    inout first: RootPolynomial, inout second: RootPolynomial) -> Bool:
    var affine = RootPolynomial()
    affine.coefficients[0] = offset
    affine.coefficients[1] = slope
    affine.degree = 1
    affine = root_poly_mod(affine, polynomial)
    var powered = root_polynomial_power_mod(affine, (ROOT_MODULUS - 1) // 2, polynomial)
    if powered.degree < 0:
        powered.coefficients[0] = ROOT_MODULUS - 1
        powered.degree = 0
    else:
        powered.coefficients[0] = root_normalize(powered.coefficients[0] - 1)
    root_trim(inout powered)
    let part = root_polynomial_gcd(polynomial, powered)
    if part.degree <= 0 or part.degree >= polynomial.degree:
        return False
    first = part
    second = root_divide_exact(polynomial, part)
    return True

fn root_collect_roots(polynomial: RootPolynomial,
    inout roots: InlineArray[Int64, ROOT_MAX_N], inout root_count: Int, state_input: Int64):
    if polynomial.degree == 1:
        roots[root_count] = root_normalize(-polynomial.coefficients[0] *
            root_power_mod(polynomial.coefficients[1], ROOT_MODULUS - 2))
        root_count += 1
        return
    var state = state_input
    var first = RootPolynomial()
    var second = RootPolynomial()
    for _ in range(32):
        state = state * 48271 % ROOT_PRNG_MODULUS
        var slope = state % ROOT_MODULUS
        if slope == 0:
            slope = 1
        state = state * 48271 % ROOT_PRNG_MODULUS
        let offset = state % ROOT_MODULUS
        if root_split_with_affine(polynomial, slope, offset, inout first, inout second):
            root_collect_roots(first, inout roots, inout root_count, state)
            root_collect_roots(second, inout roots, inout root_count, state + 1)
            return
    for offset in range(ROOT_MODULUS):
        if root_split_with_affine(polynomial, 1, Int64(offset), inout first, inout second):
            root_collect_roots(first, inout roots, inout root_count, state)
            root_collect_roots(second, inout roots, inout root_count, state + Int64(offset) + 1)
            return

fn root_find_roots(polynomial: RootPolynomial,
    inout roots: InlineArray[Int64, ROOT_MAX_N]) -> Int:
    if polynomial.degree <= 0:
        return 0
    var x = RootPolynomial()
    x.coefficients[1] = 1
    x.degree = 1
    let x_mod = root_poly_mod(x, polynomial)
    var x_to_p = root_polynomial_power_mod(x_mod, ROOT_MODULUS, polynomial)
    let largest = max(x_to_p.degree, x_mod.degree)
    if largest >= 0:
        for i in range(largest + 1):
            let left = x_to_p.coefficients[i] if i <= x_to_p.degree else 0
            let right = x_mod.coefficients[i] if i <= x_mod.degree else 0
            x_to_p.coefficients[i] = root_normalize(left - right)
    x_to_p.degree = largest
    root_trim(inout x_to_p)
    let linear_part = root_polynomial_gcd(polynomial, x_to_p)
    if linear_part.degree <= 0:
        return 0
    var seed: Int64 = 1
    for i in range(polynomial.degree + 1):
        seed = (seed * 31 + polynomial.coefficients[i]) % (ROOT_PRNG_MODULUS - 1) + 1
    var root_count = 0
    root_collect_roots(linear_part, inout roots, inout root_count, seed)
    for i in range(root_count):
        for j in range(i + 1, root_count):
            if roots[j] < roots[i]:
                let saved = roots[i]
                roots[i] = roots[j]
                roots[j] = saved
    return root_count

fn root_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("polynomial_root_finding")
fn polynomial_root_finding(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > ROOT_MAX_INPUT:
        return -1
    let degree_value = input[0]
    if degree_value < 0 or degree_value > ROOT_MAX_N or Int(length) != Int(degree_value) + 2:
        return -1
    var polynomial = RootPolynomial()
    polynomial.degree = Int(degree_value)
    for i in range(polynomial.degree + 1):
        let coefficient = input[i + 1]
        if coefficient < 0 or coefficient >= ROOT_MODULUS:
            return -1
        polynomial.coefficients[i] = coefficient
    if polynomial.coefficients[polynomial.degree] == 0:
        return -1
    var roots = InlineArray[Int64, ROOT_MAX_N]()
    let root_count = root_find_roots(polynomial, inout roots)
    let bytes = 8 * (root_count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2
    root_store_le(output, 0, Int64(root_count))
    for i in range(root_count):
        root_store_le(output, 8 * (i + 1), roots[i])
    return Int64(bytes)
