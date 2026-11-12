package factorization_of_polynomials

import "core:c"

MAX_N :: 8
MAX_POLY :: MAX_N + 1
MAX_FACTORS :: MAX_N
MAX_INPUT :: c.size_t(12)
MAX_OUTPUT_BYTES :: 216
Poly :: [MAX_POLY]i64

Factor :: struct {
	polynomial: Poly,
	degree: int,
	multiplicity: i64,
}

power_small :: proc(base_input, exponent: int) -> int {
	value := 1
	for i := 0; i < exponent; i += 1 { value *= base_input }
	return value
}

monic_from_code :: proc(degree, code_input, prime: int) -> Poly {
	polynomial := Poly{}
	code := code_input
	for i := 0; i < degree; i += 1 {
		polynomial[i] = i64(code % prime)
		code /= prime
	}
	polynomial[degree] = 1
	return polynomial
}

exact_quotient :: proc(polynomial: Poly, degree: int, divisor: Poly,
	divisor_degree, prime: int) -> (Poly, bool) {
	if degree < divisor_degree do return Poly{}, false
	remainder := polynomial
	quotient := Poly{}
	quotient_degree := degree - divisor_degree
	for shift := quotient_degree; shift >= 0; shift -= 1 {
		factor := remainder[shift + divisor_degree]
		quotient[shift] = factor
		for j := 0; j <= divisor_degree; j += 1 {
			value := (remainder[shift + j] - factor * divisor[j]) % i64(prime)
			if value < 0 do value += i64(prime)
			remainder[shift + j] = value
		}
	}
	for i := 0; i < divisor_degree; i += 1 { if remainder[i] != 0 do return Poly{}, false }
	return quotient, true
}

irreducible :: proc(candidate: Poly, degree, prime: int) -> bool {
	for divisor_degree := 1; divisor_degree <= degree / 2; divisor_degree += 1 {
		for code := 0; code < power_small(prime, divisor_degree); code += 1 {
			divisor := monic_from_code(divisor_degree, code, prime)
			_, divides := exact_quotient(candidate, degree, divisor, divisor_degree, prime)
			if divides do return false
		}
	}
	return true
}

factor_after :: proc(left, right: Factor) -> bool {
	if left.degree != right.degree do return left.degree > right.degree
	for i := 0; i <= left.degree; i += 1 {
		if left.polynomial[i] != right.polynomial[i] do return left.polynomial[i] > right.polynomial[i]
	}
	return false
}

factorize :: proc(coefficients: Poly, input_degree, prime: int) -> ([MAX_FACTORS]Factor, int) {
	var factors: [MAX_FACTORS]Factor
	work := coefficients
	work_degree := input_degree
	factor_count := 0
	for degree := 1; degree <= input_degree / 2; degree += 1 {
		for code := 0; code < power_small(prime, degree); code += 1 {
			candidate := monic_from_code(degree, code, prime)
			if !irreducible(candidate, degree, prime) do continue
			multiplicity := i64(0)
			for work_degree >= degree {
				quotient, divides := exact_quotient(work, work_degree, candidate, degree, prime)
				if !divides do break
				work = quotient
				work_degree -= degree
				multiplicity += 1
			}
			if multiplicity != 0 {
				factors[factor_count] = Factor{polynomial = candidate, degree = degree, multiplicity = multiplicity}
				factor_count += 1
			}
		}
	}
	if work_degree > 0 {
		factors[factor_count] = Factor{polynomial = work, degree = work_degree, multiplicity = 1}
		factor_count += 1
	}
	for i := 0; i < factor_count; i += 1 {
		for j := i + 1; j < factor_count; j += 1 {
			if factor_after(factors[i], factors[j]) {
				temporary := factors[i]
				factors[i] = factors[j]
				factors[j] = temporary
			}
		}
	}
	return factors, factor_count
}

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
factorization_of_polynomials :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	degree_value := input[0]
	prime_value := input[1]
	if degree_value < 0 || degree_value > i64(MAX_N) ||
		(prime_value != 2 && prime_value != 3 && prime_value != 5) do return -1
	degree := int(degree_value)
	prime := int(prime_value)
	if int(length) != degree + 3 || input[degree + 2] != 1 do return -1
	coefficients := Poly{}
	for i := 0; i <= degree; i += 1 {
		coefficient := input[i + 2]
		if coefficient < 0 || coefficient >= prime_value do return -1
		coefficients[i] = coefficient
	}

	factors, factor_count := factorize(coefficients, degree, prime)
	words := 1
	for i := 0; i < factor_count; i += 1 { words += factors[i].degree + 3 }
	bytes := words * 8
	if bytes > MAX_OUTPUT_BYTES do return -1
	if output == nil || int(capacity) < bytes do return -2
	word := 0
	store_le(output, word * 8, i64(factor_count))
	word += 1
	for i := 0; i < factor_count; i += 1 {
		store_le(output, word * 8, factors[i].multiplicity)
		word += 1
		store_le(output, word * 8, i64(factors[i].degree))
		word += 1
		for j := 0; j <= factors[i].degree; j += 1 {
			store_le(output, word * 8, factors[i].polynomial[j])
			word += 1
		}
	}
	return i64(bytes)
}
