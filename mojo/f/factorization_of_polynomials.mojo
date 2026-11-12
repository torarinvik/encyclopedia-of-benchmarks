from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime FACTOR_MAX_N = 8
comptime FACTOR_MAX_POLY = 9
comptime FACTOR_MAX_FACTORS = 8
comptime FACTOR_MAX_INPUT = 12
comptime FACTOR_MAX_OUTPUT_BYTES = 216

fn factor_power_small(base: Int, exponent: Int) -> Int:
    var value = 1
    for _ in range(exponent):
        value *= base
    return value

fn factor_monic_from_code(degree: Int, code_input: Int, prime: Int) -> InlineArray[Int64, FACTOR_MAX_POLY]:
    var polynomial = InlineArray[Int64, FACTOR_MAX_POLY]()
    var code = code_input
    for i in range(degree):
        polynomial[i] = Int64(code % prime)
        code //= prime
    polynomial[degree] = 1
    return polynomial

fn factor_exact_quotient(
    polynomial: InlineArray[Int64, FACTOR_MAX_POLY], degree: Int,
    divisor: InlineArray[Int64, FACTOR_MAX_POLY], divisor_degree: Int,
    prime: Int, inout quotient: InlineArray[Int64, FACTOR_MAX_POLY],
) -> Bool:
    if degree < divisor_degree:
        return False
    var remainder = polynomial
    for i in range(FACTOR_MAX_POLY):
        quotient[i] = 0
    let quotient_degree = degree - divisor_degree
    for step in range(quotient_degree + 1):
        let shift = quotient_degree - step
        let factor = remainder[shift + divisor_degree]
        quotient[shift] = factor
        for j in range(divisor_degree + 1):
            var value = (remainder[shift + j] - factor * divisor[j]) % Int64(prime)
            if value < 0:
                value += Int64(prime)
            remainder[shift + j] = value
    for i in range(divisor_degree):
        if remainder[i] != 0:
            return False
    return True

fn factor_irreducible(
    candidate: InlineArray[Int64, FACTOR_MAX_POLY], degree: Int, prime: Int,
) -> Bool:
    for divisor_degree in range(1, degree // 2 + 1):
        let limit = factor_power_small(prime, divisor_degree)
        for code in range(limit):
            let divisor = factor_monic_from_code(divisor_degree, code, prime)
            var quotient = InlineArray[Int64, FACTOR_MAX_POLY]()
            if factor_exact_quotient(candidate, degree, divisor, divisor_degree, prime, quotient):
                return False
    return True

fn factor_after(
    left: InlineArray[Int64, FACTOR_MAX_POLY], left_degree: Int,
    right: InlineArray[Int64, FACTOR_MAX_POLY], right_degree: Int,
) -> Bool:
    if left_degree != right_degree:
        return left_degree > right_degree
    for i in range(left_degree + 1):
        if left[i] != right[i]:
            return left[i] > right[i]
    return False

fn factor_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("factorization_of_polynomials")
fn factorization_of_polynomials(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > FACTOR_MAX_INPUT:
        return -1
    let degree_value = input[0]
    let prime_value = input[1]
    if degree_value < 0 or degree_value > FACTOR_MAX_N or
       (prime_value != 2 and prime_value != 3 and prime_value != 5):
        return -1
    let degree = Int(degree_value)
    let prime = Int(prime_value)
    if Int(length) != degree + 3 or input[degree + 2] != 1:
        return -1
    var coefficients = InlineArray[Int64, FACTOR_MAX_POLY]()
    for i in range(degree + 1):
        let coefficient = input[i + 2]
        if coefficient < 0 or coefficient >= prime_value:
            return -1
        coefficients[i] = coefficient

    var factors = InlineArray[InlineArray[Int64, FACTOR_MAX_POLY], FACTOR_MAX_FACTORS]()
    var degrees = InlineArray[Int32, FACTOR_MAX_FACTORS]()
    var multiplicities = InlineArray[Int64, FACTOR_MAX_FACTORS]()
    var work = coefficients
    var work_degree = degree
    var factor_count = 0
    for candidate_degree in range(1, degree // 2 + 1):
        let limit = factor_power_small(prime, candidate_degree)
        for code in range(limit):
            let candidate = factor_monic_from_code(candidate_degree, code, prime)
            if not factor_irreducible(candidate, candidate_degree, prime):
                continue
            var quotient = InlineArray[Int64, FACTOR_MAX_POLY]()
            var multiplicity: Int64 = 0
            while work_degree >= candidate_degree:
                if not factor_exact_quotient(work, work_degree, candidate,
                    candidate_degree, prime, quotient):
                    break
                work = quotient
                work_degree -= candidate_degree
                multiplicity += 1
            if multiplicity != 0:
                factors[factor_count] = candidate
                degrees[factor_count] = Int32(candidate_degree)
                multiplicities[factor_count] = multiplicity
                factor_count += 1
    if work_degree > 0:
        factors[factor_count] = work
        degrees[factor_count] = Int32(work_degree)
        multiplicities[factor_count] = 1
        factor_count += 1

    for i in range(factor_count):
        for j in range(i + 1, factor_count):
            if factor_after(factors[i], Int(degrees[i]), factors[j], Int(degrees[j])):
                let saved_polynomial = factors[i]
                factors[i] = factors[j]
                factors[j] = saved_polynomial
                let saved_degree = degrees[i]
                degrees[i] = degrees[j]
                degrees[j] = saved_degree
                let saved_multiplicity = multiplicities[i]
                multiplicities[i] = multiplicities[j]
                multiplicities[j] = saved_multiplicity

    var words = 1
    for i in range(factor_count):
        words += Int(degrees[i]) + 3
    let bytes = words * 8
    if bytes > FACTOR_MAX_OUTPUT_BYTES:
        return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2
    var word = 0
    factor_store_le(output, 8 * word, Int64(factor_count))
    word += 1
    for i in range(factor_count):
        factor_store_le(output, 8 * word, multiplicities[i])
        word += 1
        factor_store_le(output, 8 * word, Int64(degrees[i]))
        word += 1
        for j in range(Int(degrees[i]) + 1):
            factor_store_le(output, 8 * word, factors[i][j])
            word += 1
    return Int64(bytes)
