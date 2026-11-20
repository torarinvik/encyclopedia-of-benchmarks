package gao_rs_decode

import "core:c"

FIELD :: 7
MAX_N :: 7
MAX_POLYNOMIAL :: 16
MAX_INPUT_LENGTH :: 11

Polynomial :: struct {
	coefficients: [MAX_POLYNOMIAL]int,
	length: int,
}

Division_Result :: struct {
	quotient: Polynomial,
	remainder: Polynomial,
	valid: bool,
}

normalize :: proc(value: int) -> int {
	remainder := value % FIELD
	if remainder < 0 do return remainder + FIELD
	return remainder
}

zero_polynomial :: proc() -> Polynomial {
	result := Polynomial{}
	result.length = 1
	return result
}

constant_polynomial :: proc(value: int) -> Polynomial {
	result := zero_polynomial()
	result.coefficients[0] = normalize(value)
	return result
}

trim :: proc(polynomial: ^Polynomial) {
	for polynomial.length > 1 && polynomial.coefficients[polynomial.length - 1] == 0 {
		polynomial.length -= 1
	}
}

is_zero :: proc(polynomial: Polynomial) -> bool {
	return polynomial.length == 1 && polynomial.coefficients[0] == 0
}

multiply_linear :: proc(polynomial: Polynomial, root: int) -> Polynomial {
	result := zero_polynomial()
	result.length = polynomial.length + 1
	for degree := 0; degree < polynomial.length; degree += 1 {
		result.coefficients[degree] = normalize(result.coefficients[degree] - root * polynomial.coefficients[degree])
		result.coefficients[degree + 1] = normalize(result.coefficients[degree + 1] + polynomial.coefficients[degree])
	}
	trim(&result)
	return result
}

add_scaled :: proc(target, source: Polynomial, scale: int) -> Polynomial {
	result := target
	if result.length < source.length do result.length = source.length
	for degree := 0; degree < source.length; degree += 1 {
		result.coefficients[degree] = normalize(result.coefficients[degree] + scale * source.coefficients[degree])
	}
	trim(&result)
	return result
}

multiply_polynomials :: proc(left, right: Polynomial) -> Polynomial {
	result := zero_polynomial()
	result.length = left.length + right.length - 1
	for i := 0; i < left.length; i += 1 {
		for j := 0; j < right.length; j += 1 {
			result.coefficients[i + j] = normalize(result.coefficients[i + j] + left.coefficients[i] * right.coefficients[j])
		}
	}
	trim(&result)
	return result
}

divide_with_remainder :: proc(numerator, denominator: Polynomial) -> Division_Result {
	inverse := [7]int{0, 1, 4, 5, 2, 3, 6}
	if is_zero(denominator) do return Division_Result{valid = false}
	result := Division_Result{quotient = zero_polynomial(), remainder = numerator, valid = true}
	divisor := denominator
	trim(&result.remainder)
	trim(&divisor)
	inverse_lead := inverse[divisor.coefficients[divisor.length - 1]]
	for !is_zero(result.remainder) && result.remainder.length >= divisor.length {
		shift := result.remainder.length - divisor.length
		factor := normalize(result.remainder.coefficients[result.remainder.length - 1] * inverse_lead)
		if result.quotient.length < shift + 1 do result.quotient.length = shift + 1
		result.quotient.coefficients[shift] = normalize(result.quotient.coefficients[shift] + factor)
		for degree := 0; degree < divisor.length; degree += 1 {
			result.remainder.coefficients[shift + degree] = normalize(
				result.remainder.coefficients[shift + degree] - factor * divisor.coefficients[degree])
		}
		trim(&result.remainder)
	}
	trim(&result.quotient)
	return result
}

interpolate :: proc(n: int, received: ^[MAX_N]int) -> (Polynomial, Polynomial) {
	inverse := [7]int{0, 1, 4, 5, 2, 3, 6}
	vanishing := constant_polynomial(1)
	for point := 0; point < n; point += 1 do vanishing = multiply_linear(vanishing, point)
	interpolant := zero_polynomial()
	for i := 0; i < n; i += 1 {
		basis := constant_polynomial(1)
		denominator := 1
		for j := 0; j < n; j += 1 {
			if i == j do continue
			basis = multiply_linear(basis, j)
			denominator = normalize(denominator * (i - j))
		}
		scale := normalize(received[i] * inverse[denominator])
		interpolant = add_scaled(interpolant, basis, scale)
	}
	return vanishing, interpolant
}

decode :: proc(n, k, error_limit: int, received: ^[MAX_N]int) -> i64 {
	vanishing, interpolant := interpolate(n, received)
	if is_zero(interpolant) do return 1

	remainder_previous, remainder_current := vanishing, interpolant
	bezout_previous := zero_polynomial()
	bezout_current := constant_polynomial(1)
	threshold := (n + k - 1) / 2
	for !is_zero(remainder_current) && remainder_current.length - 1 > threshold {
		division := divide_with_remainder(remainder_previous, remainder_current)
		if !division.valid do return 0
		bezout_next := add_scaled(bezout_previous, multiply_polynomials(division.quotient, bezout_current), -1)
		remainder_previous, remainder_current = remainder_current, division.remainder
		bezout_previous, bezout_current = bezout_current, bezout_next
	}
	if is_zero(remainder_current) || is_zero(bezout_current) do return 0

	division := divide_with_remainder(remainder_current, bezout_current)
	if !division.valid || !is_zero(division.remainder) do return 0
	message := division.quotient
	trim(&message)
	if message.length > k do return 0

	mismatches := 0
	for x := 0; x < n; x += 1 {
		value := 0
		for degree := message.length - 1; degree >= 0; degree -= 1 {
			value = (value * x + message.coefficients[degree]) % FIELD
		}
		if value != received[x] do mismatches += 1
	}
	if mismatches > error_limit do return 0

	encoded, place := i64(1), i64(1)
	for degree := 0; degree < k; degree += 1 {
		if degree < message.length do encoded += i64(message.coefficients[degree]) * place
		place *= FIELD
	}
	return encoded
}

@(export)
gao_rs_decode :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	n_value, k_value, error_value := input[0], input[1], input[2]
	if n_value < 2 || n_value > MAX_N || k_value < 1 || k_value > 3 || k_value > n_value
		|| error_value < 0 || error_value > 2 do return -1
	n, k, error_limit := int(n_value), int(k_value), int(error_value)
	if 2 * error_limit > n - k || int(length) != 3 + n do return -1
	var received: [MAX_N]int
	for index := 0; index < n; index += 1 {
		symbol := input[3 + index]
		if symbol < 0 || symbol >= FIELD do return -1
		received[index] = int(symbol)
	}
	return decode(n, k, error_limit, &received)
}
