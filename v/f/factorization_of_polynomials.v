module factorization_of_polynomials

const max_n = 8
const max_poly = max_n + 1
const max_factors = max_n
const max_input = 12
const max_output_bytes = 216

struct Factor {
	polynomial [max_poly]i64
	degree int
	multiplicity i64
}

fn power_small(base int, exponent int) int {
	mut value := 1
	for _ in 0 .. exponent { value *= base }
	return value
}

fn monic_from_code(degree int, code_input int, prime int) [max_poly]i64 {
	mut polynomial := [max_poly]i64{}
	mut code := code_input
	for i in 0 .. degree {
		polynomial[i] = i64(code % prime)
		code /= prime
	}
	polynomial[degree] = 1
	return polynomial
}

fn exact_quotient(polynomial [max_poly]i64, degree int, divisor [max_poly]i64,
	divisor_degree int, prime int, mut quotient [max_poly]i64) bool {
	if degree < divisor_degree { return false }
	mut remainder := polynomial
	for i in 0 .. max_poly { quotient[i] = 0 }
	quotient_degree := degree - divisor_degree
	for step in 0 .. quotient_degree + 1 {
		shift := quotient_degree - step
		factor := remainder[shift + divisor_degree]
		quotient[shift] = factor
		for j in 0 .. divisor_degree + 1 {
			mut value := (remainder[shift + j] - factor * divisor[j]) % i64(prime)
			if value < 0 { value += i64(prime) }
			remainder[shift + j] = value
		}
	}
	for i in 0 .. divisor_degree { if remainder[i] != 0 { return false } }
	return true
}

fn irreducible(candidate [max_poly]i64, degree int, prime int) bool {
	for divisor_degree in 1 .. degree / 2 + 1 {
		limit := power_small(prime, divisor_degree)
		for code in 0 .. limit {
			divisor := monic_from_code(divisor_degree, code, prime)
			mut quotient := [max_poly]i64{}
			if exact_quotient(candidate, degree, divisor, divisor_degree, prime, mut quotient) {
				return false
			}
		}
	}
	return true
}

fn factor_after(left Factor, right Factor) bool {
	if left.degree != right.degree { return left.degree > right.degree }
	for i in 0 .. left.degree + 1 {
		if left.polynomial[i] != right.polynomial[i] {
			return left.polynomial[i] > right.polynomial[i]
		}
	}
	return false
}

fn factorize(coefficients [max_poly]i64, input_degree int, prime int) ([max_factors]Factor, int) {
	mut factors := [max_factors]Factor{}
	mut work := coefficients
	mut work_degree := input_degree
	mut factor_count := 0
	for degree in 1 .. input_degree / 2 + 1 {
		limit := power_small(prime, degree)
		for code in 0 .. limit {
			candidate := monic_from_code(degree, code, prime)
			if !irreducible(candidate, degree, prime) { continue }
			mut multiplicity := i64(0)
			for work_degree >= degree {
				mut quotient := [max_poly]i64{}
				if !exact_quotient(work, work_degree, candidate, degree, prime, mut quotient) { break }
				work = quotient
				work_degree -= degree
				multiplicity++
			}
			if multiplicity != 0 {
				factors[factor_count] = Factor{polynomial: candidate, degree: degree, multiplicity: multiplicity}
				factor_count++
			}
		}
	}
	if work_degree > 0 {
		factors[factor_count] = Factor{polynomial: work, degree: work_degree, multiplicity: 1}
		factor_count++
	}
	for i in 0 .. factor_count {
		for j in i + 1 .. factor_count {
			if factor_after(factors[i], factors[j]) {
				temporary := factors[i]
				factors[i] = factors[j]
				factors[j] = temporary
			}
		}
	}
	return factors, factor_count
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'factorization_of_polynomials']
pub fn factorization_of_polynomials(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		degree_value := input[0]
		prime_value := input[1]
		if degree_value < 0 || degree_value > max_n ||
			(prime_value != 2 && prime_value != 3 && prime_value != 5) { return -1 }
		degree := int(degree_value)
		prime := int(prime_value)
		if length != usize(degree + 3) || input[degree + 2] != 1 { return -1 }
		mut coefficients := [max_poly]i64{}
		for i in 0 .. degree + 1 {
			coefficient := input[i + 2]
			if coefficient < 0 || coefficient >= prime_value { return -1 }
			coefficients[i] = coefficient
		}

		factors, factor_count := factorize(coefficients, degree, prime)
		mut words := 1
		for i in 0 .. factor_count { words += factors[i].degree + 3 }
		bytes := words * 8
		if bytes > max_output_bytes { return -1 }
		if output == nil || capacity < usize(bytes) { return -2 }
		mut word := 0
		store_le(mut output, 8 * word, i64(factor_count))
		word++
		for i in 0 .. factor_count {
			store_le(mut output, 8 * word, factors[i].multiplicity)
			word++
			store_le(mut output, 8 * word, i64(factors[i].degree))
			word++
			for j in 0 .. factors[i].degree + 1 {
				store_le(mut output, 8 * word, factors[i].polynomial[j])
				word++
			}
		}
		return i64(bytes)
	}
}
