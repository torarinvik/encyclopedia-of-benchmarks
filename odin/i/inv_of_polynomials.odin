package inv_of_polynomials

import "core:c"

MODULUS :: i64(998244353)
MAX_LENGTH :: 6
MAX_INPUT :: 14
CAPACITY :: 16
Poly :: [CAPACITY]i64
Division :: struct {
	quotient: Poly,
	quotient_length: int,
	remainder: Poly,
	remainder_length: int,
}

power_mod :: proc(base_input, exponent_input: i64) -> i64 {
	base, exponent, result := base_input, exponent_input, i64(1)
	for exponent > 0 {
		if exponent % 2 != 0 do result = result * base % MODULUS
		base = base * base % MODULUS
		exponent /= 2
	}
	return result
}

trim :: proc(poly: Poly, length_input: int) -> int {
	length := length_input
	for length > 0 && poly[length - 1] == 0 { length -= 1 }
	return length
}

divide_poly :: proc(dividend: Poly, dividend_length: int, divisor: Poly, divisor_length: int) -> Division {
	quotient := Poly{}
	remainder := dividend
	remainder_length := trim(remainder, dividend_length)
	if remainder_length >= divisor_length {
		inverse_lead := power_mod(divisor[divisor_length - 1], MODULUS - 2)
		for remainder_length >= divisor_length {
			shift := remainder_length - divisor_length
			factor := remainder[remainder_length - 1] * inverse_lead % MODULUS
			quotient[shift] = factor
			for j := 0; j < divisor_length; j += 1 {
				value := (remainder[shift + j] - factor * divisor[j]) % MODULUS
				if value < 0 do value += MODULUS
				remainder[shift + j] = value
			}
			remainder_length = trim(remainder, remainder_length)
		}
	}
	quotient_bound := 0
	if dividend_length >= divisor_length do quotient_bound = dividend_length - divisor_length + 1
	return Division{quotient, trim(quotient, quotient_bound), remainder, remainder_length}
}

multiply :: proc(left: Poly, left_length: int, right: Poly, right_length: int) -> Division {
	product := Poly{}
	if left_length == 0 || right_length == 0 do return Division{product, 0, product, 0}
	for i := 0; i < left_length; i += 1 {
		for j := 0; j < right_length; j += 1 {
			if i + j < CAPACITY do product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS
		}
	}
	bound := min(CAPACITY, left_length + right_length - 1)
	length := trim(product, bound)
	return Division{product, length, product, length}
}

subtract :: proc(left: Poly, left_length: int, right: Poly, right_length: int) -> Division {
	difference := Poly{}
	bound := max(left_length, right_length)
	for i := 0; i < bound; i += 1 {
		a := i64(0)
		b := i64(0)
		if i < left_length do a = left[i]
		if i < right_length do b = right[i]
		difference[i] = (a - b + MODULUS) % MODULUS
	}
	length := trim(difference, bound)
	return Division{difference, length, difference, length}
}

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
inv_of_polynomials :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	if input[0] < 1 || input[0] > MAX_LENGTH || input[1] < 1 || input[1] > MAX_LENGTH do return -1
	n, m := int(input[0]), int(input[1])
	if int(length) != 2 + n + m do return -1
	f, g := Poly{}, Poly{}
	for i := 0; i < n; i += 1 {
		f[i] = input[2 + i]
		if f[i] < 0 || f[i] >= MODULUS do return -1
	}
	for i := 0; i < m; i += 1 {
		g[i] = input[2 + n + i]
		if g[i] < 0 || g[i] >= MODULUS do return -1
	}
	if f[n - 1] == 0 || g[m - 1] == 0 do return -1

	inverse := Poly{}
	inverse_length := 0
	if m > 1 {
		initial := divide_poly(f, n, g, m)
		r0, r1 := g, initial.remainder
		r0_length, r1_length := m, initial.remainder_length
		s0 := Poly{}
		s0_length := 0
		s1 := Poly{}
		s1[0] = 1
		s1_length := 1
		for r1_length > 0 {
			division := divide_poly(r0, r0_length, r1, r1_length)
			product := multiply(division.quotient, division.quotient_length, s1, s1_length)
			next_s := subtract(s0, s0_length, product.quotient, product.quotient_length)
			r0, r1 = r1, division.remainder
			r0_length, r1_length = r1_length, division.remainder_length
			s0, s1 = s1, next_s.quotient
			s0_length, s1_length = s1_length, next_s.quotient_length
		}
		if r0_length != 1 do return -1
		scale := power_mod(r0[0], MODULUS - 2)
		for i := 0; i < s0_length; i += 1 { inverse[i] = s0[i] * scale % MODULUS }
		inverse_length = trim(inverse, s0_length)
	}

	bytes := 8 * inverse_length
	if output == nil || int(capacity) < bytes do return -2
	for i := 0; i < inverse_length; i += 1 { store_le(output, 8 * i, inverse[i]) }
	return i64(bytes)
}
