package polynomial_root_finding

import "core:c"

MODULUS :: i64(998244353)
PRNG_MODULUS :: i64(2147483647)
MAX_N :: 8
MAX_INPUT :: c.size_t(10)
MAX_PRODUCT :: 17

Polynomial :: struct {
	coefficients: [MAX_PRODUCT]i64,
	degree: int,
}

normalize :: proc(value_input: i64) -> i64 {
	value := value_input % MODULUS
	if value < 0 do value += MODULUS
	return value
}

power_mod :: proc(base_input, exponent_input: i64) -> i64 {
	base := base_input
	exponent := exponent_input
	result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 do result = result * base % MODULUS
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

zero_poly :: proc() -> Polynomial {
	return Polynomial{degree = -1}
}

trim :: proc(poly: ^Polynomial) {
	for poly.degree >= 0 && poly.coefficients[poly.degree] == 0 { poly.degree -= 1 }
}

poly_mod :: proc(value_input: Polynomial, divisor: Polynomial) -> Polynomial {
	value := value_input
	if divisor.degree <= 0 || value.degree < 0 do return zero_poly()
	inverse := power_mod(divisor.coefficients[divisor.degree], MODULUS - 2)
	for value.degree >= divisor.degree {
		shift := value.degree - divisor.degree
		factor := value.coefficients[value.degree] * inverse % MODULUS
		for i := 0; i <= divisor.degree; i += 1 {
			value.coefficients[shift + i] = normalize(value.coefficients[shift + i] - factor * divisor.coefficients[i])
		}
		trim(&value)
	}
	return value
}

multiply_mod :: proc(left, right, modulus_poly: Polynomial) -> Polynomial {
	if left.degree < 0 || right.degree < 0 do return zero_poly()
	product: [MAX_PRODUCT]i64
	for i := 0; i <= left.degree; i += 1 {
		for j := 0; j <= right.degree; j += 1 {
			product[i + j] = (product[i + j] + left.coefficients[i] * right.coefficients[j]) % MODULUS
		}
	}
	expanded := zero_poly()
	expanded.degree = left.degree + right.degree
	for i := 0; i <= expanded.degree; i += 1 { expanded.coefficients[i] = product[i] }
	trim(&expanded)
	return poly_mod(expanded, modulus_poly)
}

polynomial_power_mod :: proc(base_input: Polynomial, exponent_input: i64, modulus_poly: Polynomial) -> Polynomial {
	base := poly_mod(base_input, modulus_poly)
	exponent := exponent_input
	result := zero_poly()
	result.coefficients[0] = 1
	result.degree = 0
	for exponent > 0 {
		if exponent & 1 != 0 do result = multiply_mod(result, base, modulus_poly)
		base = multiply_mod(base, base, modulus_poly)
		exponent >>= 1
	}
	return result
}

polynomial_gcd :: proc(left_input, right_input: Polynomial) -> Polynomial {
	left := left_input
	right := right_input
	for right.degree >= 0 {
		remainder := poly_mod(left, right)
		left = right
		right = remainder
	}
	if left.degree < 0 do return left
	inverse := power_mod(left.coefficients[left.degree], MODULUS - 2)
	for i := 0; i <= left.degree; i += 1 { left.coefficients[i] = left.coefficients[i] * inverse % MODULUS }
	return left
}

divide_exact :: proc(value_input, divisor: Polynomial) -> Polynomial {
	value := value_input
	quotient := zero_poly()
	quotient.degree = value.degree - divisor.degree
	if quotient.degree < 0 do return quotient
	inverse := power_mod(divisor.coefficients[divisor.degree], MODULUS - 2)
	for value.degree >= divisor.degree {
		shift := value.degree - divisor.degree
		factor := value.coefficients[value.degree] * inverse % MODULUS
		quotient.coefficients[shift] = factor
		for i := 0; i <= divisor.degree; i += 1 {
			value.coefficients[shift + i] = normalize(value.coefficients[shift + i] - factor * divisor.coefficients[i])
		}
		trim(&value)
	}
	trim(&quotient)
	return quotient
}

split_with_affine :: proc(poly: Polynomial, slope, offset: i64) -> (Polynomial, Polynomial, bool) {
	affine := zero_poly()
	affine.coefficients[0] = offset
	affine.coefficients[1] = slope
	affine.degree = 1
	affine = poly_mod(affine, poly)
	powered := polynomial_power_mod(affine, (MODULUS - 1) / 2, poly)
	if powered.degree < 0 {
		powered.coefficients[0] = MODULUS - 1
		powered.degree = 0
	} else {
		powered.coefficients[0] = normalize(powered.coefficients[0] - 1)
	}
	trim(&powered)
	part := polynomial_gcd(poly, powered)
	if part.degree <= 0 || part.degree >= poly.degree do return zero_poly(), zero_poly(), false
	return part, divide_exact(poly, part), true
}

collect_roots :: proc(poly: Polynomial, roots: ^[MAX_N]i64, root_count: ^int, state_input: i64) {
	if poly.degree == 1 {
		roots[root_count^] = normalize(-poly.coefficients[0] * power_mod(poly.coefficients[1], MODULUS - 2))
		root_count^ += 1
		return
	}
	state := state_input
	for attempt := 0; attempt < 32; attempt += 1 {
		state = state * 48271 % PRNG_MODULUS
		slope := state % MODULUS
		if slope == 0 do slope = 1
		state = state * 48271 % PRNG_MODULUS
		offset := state % MODULUS
		first, second, success := split_with_affine(poly, slope, offset)
		if success {
			collect_roots(first, roots, root_count, state)
			collect_roots(second, roots, root_count, state + 1)
			return
		}
	}
	for offset := i64(0); offset < MODULUS; offset += 1 {
		first, second, success := split_with_affine(poly, 1, offset)
		if success {
			collect_roots(first, roots, root_count, state)
			collect_roots(second, roots, root_count, state + offset + 1)
			return
		}
	}
}

find_roots :: proc(poly: Polynomial, roots: ^[MAX_N]i64) -> int {
	if poly.degree <= 0 do return 0
	x := zero_poly()
	x.coefficients[1] = 1
	x.degree = 1
	x_mod := poly_mod(x, poly)
	x_to_p := polynomial_power_mod(x_mod, MODULUS, poly)
	largest := max(x_to_p.degree, x_mod.degree)
	for i := 0; i <= largest; i += 1 {
		left := i64(0)
		right := i64(0)
		if i <= x_to_p.degree do left = x_to_p.coefficients[i]
		if i <= x_mod.degree do right = x_mod.coefficients[i]
		x_to_p.coefficients[i] = normalize(left - right)
	}
	x_to_p.degree = largest
	trim(&x_to_p)
	linear_part := polynomial_gcd(poly, x_to_p)
	if linear_part.degree <= 0 do return 0
	seed := i64(1)
	for i := 0; i <= poly.degree; i += 1 { seed = (seed * 31 + poly.coefficients[i]) % (PRNG_MODULUS - 1) + 1 }
	root_count := 0
	collect_roots(linear_part, roots, &root_count, seed)
	for i := 0; i < root_count; i += 1 {
		for j := i + 1; j < root_count; j += 1 {
			if roots[j] < roots[i] { temporary := roots[i]; roots[i] = roots[j]; roots[j] = temporary }
		}
	}
	return root_count
}

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
polynomial_root_finding :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT || input[0] < 0 || input[0] > MAX_N do return -1
	degree := int(input[0])
	if int(length) != degree + 2 do return -1
	polynomial := zero_poly()
	polynomial.degree = degree
	for i := 0; i <= degree; i += 1 {
		if input[i + 1] < 0 || input[i + 1] >= MODULUS do return -1
		polynomial.coefficients[i] = input[i + 1]
	}
	if polynomial.coefficients[degree] == 0 do return -1
	roots: [MAX_N]i64
	root_count := find_roots(polynomial, &roots)
	bytes := c.size_t(8 * (root_count + 1))
	if output == nil || capacity < bytes do return -2
	store_le(output, 0, i64(root_count))
	for i := 0; i < root_count; i += 1 { store_le(output, 8 * (i + 1), roots[i]) }
	return i64(bytes)
}
