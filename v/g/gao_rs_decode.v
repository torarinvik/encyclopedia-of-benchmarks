module gao_rs_decode

const field = 7
const max_n = 7
const max_polynomial = 16
const max_input_length = 11

struct Polynomial {
mut:
	coefficients [max_polynomial]int
	length int
}

struct DivisionResult {
	mut:
	quotient Polynomial
	remainder Polynomial
	valid bool
}

fn normalize(value int) int {
	remainder := value % field
	return if remainder < 0 { remainder + field } else { remainder }
}

fn zero_polynomial() Polynomial {
	return Polynomial{length: 1}
}

fn constant_polynomial(value int) Polynomial {
	mut result := zero_polynomial()
	result.coefficients[0] = normalize(value)
	return result
}

fn trim(mut polynomial Polynomial) {
	for polynomial.length > 1 && polynomial.coefficients[polynomial.length - 1] == 0 {
		polynomial.length--
	}
}

fn is_zero(polynomial Polynomial) bool {
	return polynomial.length == 1 && polynomial.coefficients[0] == 0
}

fn multiply_linear(polynomial Polynomial, root int) Polynomial {
	mut result := zero_polynomial()
	result.length = polynomial.length + 1
	for degree in 0 .. polynomial.length {
		result.coefficients[degree] = normalize(result.coefficients[degree] - root * polynomial.coefficients[degree])
		result.coefficients[degree + 1] = normalize(result.coefficients[degree + 1] + polynomial.coefficients[degree])
	}
	trim(mut result)
	return result
}

fn add_scaled(target Polynomial, source Polynomial, scale int) Polynomial {
	mut result := target
	if result.length < source.length { result.length = source.length }
	for degree in 0 .. source.length {
		result.coefficients[degree] = normalize(result.coefficients[degree] + scale * source.coefficients[degree])
	}
	trim(mut result)
	return result
}

fn multiply_polynomials(left Polynomial, right Polynomial) Polynomial {
	mut result := zero_polynomial()
	result.length = left.length + right.length - 1
	for i in 0 .. left.length {
		for j in 0 .. right.length {
			result.coefficients[i + j] = normalize(result.coefficients[i + j] + left.coefficients[i] * right.coefficients[j])
		}
	}
	trim(mut result)
	return result
}

fn divide_with_remainder(numerator Polynomial, denominator Polynomial) DivisionResult {
	if is_zero(denominator) { return DivisionResult{valid: false} }
	inverse := [7]int{0, 1, 4, 5, 2, 3, 6}
	mut result := DivisionResult{quotient: zero_polynomial(), remainder: numerator, valid: true}
	mut divisor := denominator
	trim(mut result.remainder)
	trim(mut divisor)
	inverse_lead := inverse[divisor.coefficients[divisor.length - 1]]
	for !is_zero(result.remainder) && result.remainder.length >= divisor.length {
		shift := result.remainder.length - divisor.length
		factor := normalize(result.remainder.coefficients[result.remainder.length - 1] * inverse_lead)
		if result.quotient.length < shift + 1 { result.quotient.length = shift + 1 }
		result.quotient.coefficients[shift] = normalize(result.quotient.coefficients[shift] + factor)
		for degree in 0 .. divisor.length {
			result.remainder.coefficients[shift + degree] = normalize(
				result.remainder.coefficients[shift + degree] - factor * divisor.coefficients[degree])
		}
		trim(mut result.remainder)
	}
	trim(mut result.quotient)
	return result
}

fn interpolate(n int, received &int) (Polynomial, Polynomial) {
	inverse := [7]int{0, 1, 4, 5, 2, 3, 6}
	mut vanishing := constant_polynomial(1)
	for point in 0 .. n { vanishing = multiply_linear(vanishing, point) }
	mut interpolant := zero_polynomial()
	unsafe {
		for i in 0 .. n {
			mut basis := constant_polynomial(1)
			mut denominator := 1
			for j in 0 .. n {
				if i == j { continue }
				basis = multiply_linear(basis, j)
				denominator = normalize(denominator * (i - j))
			}
			scale := normalize(received[i] * inverse[denominator])
			interpolant = add_scaled(interpolant, basis, scale)
		}
	}
	return vanishing, interpolant
}

fn decode(n int, k int, error_limit int, received &int) i64 {
	vanishing, interpolant := interpolate(n, received)
	if is_zero(interpolant) { return 1 }

	mut remainder_previous := vanishing
	mut remainder_current := interpolant
	mut bezout_previous := zero_polynomial()
	mut bezout_current := constant_polynomial(1)
	threshold := (n + k - 1) / 2
	for !is_zero(remainder_current) && remainder_current.length - 1 > threshold {
		division := divide_with_remainder(remainder_previous, remainder_current)
		if !division.valid { return 0 }
		bezout_next := add_scaled(bezout_previous,
			multiply_polynomials(division.quotient, bezout_current), -1)
		remainder_previous, remainder_current = remainder_current, division.remainder
		bezout_previous, bezout_current = bezout_current, bezout_next
	}
	if is_zero(remainder_current) || is_zero(bezout_current) { return 0 }

	division := divide_with_remainder(remainder_current, bezout_current)
	if !division.valid || !is_zero(division.remainder) { return 0 }
	mut message := division.quotient
	trim(mut message)
	if message.length > k { return 0 }

	mut mismatches := 0
	unsafe {
		for x in 0 .. n {
			mut value := 0
			for degree := message.length - 1; degree >= 0; degree-- {
				value = (value * x + message.coefficients[degree]) % field
			}
			if value != received[x] { mismatches++ }
		}
	}
	if mismatches > error_limit { return 0 }

	mut encoded := i64(1)
	mut place := i64(1)
	for degree in 0 .. k {
		if degree < message.length { encoded += i64(message.coefficients[degree]) * place }
		place *= field
	}
	return encoded
}

@[export: 'gao_rs_decode']
pub fn gao_rs_decode(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > usize(max_input_length) { return -1 }
		n_value, k_value, error_value := input[0], input[1], input[2]
		if n_value < 2 || n_value > i64(max_n) || k_value < 1 || k_value > 3
			|| k_value > n_value || error_value < 0 || error_value > 2 { return -1 }
		n, k, error_limit := int(n_value), int(k_value), int(error_value)
		if 2 * error_limit > n - k || length != usize(3 + n) { return -1 }
		mut received := [max_n]int{}
		for index in 0 .. n {
			symbol := input[3 + index]
			if symbol < 0 || symbol >= i64(field) { return -1 }
			received[index] = int(symbol)
		}
		return decode(n, k, error_limit, received[0])
	}
}
