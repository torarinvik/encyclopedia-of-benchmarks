package polynomial_interpolation_on_geometric_sequence

import "core:c"

MODULUS :: i64(998244353)
MAX_N :: 8
MAX_INPUT :: 11
Points :: [MAX_N]i64
Differences :: [MAX_N]i64
Newton_Coefficients :: [MAX_N]i64
Result_Coefficients :: [MAX_N]i64
Basis_Coefficients :: [MAX_N + 1]i64

normalize :: proc(value: i64) -> i64 {
	value %= MODULUS
	if value < 0 do value += MODULUS
	return value
}

power_mod :: proc(base_value, exponent_value: i64) -> i64 {
	base := base_value
	exponent := exponent_value
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % MODULUS
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
polynomial_interpolation_on_geometric_sequence :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	if input[0] < 0 || input[0] > MAX_N do return -1
	n := int(input[0])
	a := input[1]
	r := input[2]
	if int(length) != 3 + n || a < 0 || a >= MODULUS || r < 0 || r >= MODULUS do return -1

	points: Points
	differences: Differences
	newton: Newton_Coefficients
	point := a
	for i := 0; i < n; i += 1 {
		points[i] = point
		differences[i] = input[3 + i]
		if differences[i] < 0 || differences[i] >= MODULUS do return -1
		for j := 0; j < i; j += 1 { if points[i] == points[j] do return -1 }
		point = point * r % MODULUS
	}

	bytes := 8 * n
	if output == nil || int(capacity) < bytes do return -2
	if n == 0 do return 0
	newton[0] = differences[0]
	for order := 1; order < n; order += 1 {
		r_order := power_mod(r, i64(order))
		end := n
		for end > order {
			end -= 1
			r_factor := power_mod(r, i64(end - order))
			denominator := a * r_factor % MODULUS
			denominator = denominator * (r_order - 1) % MODULUS
			inverse := power_mod(normalize(denominator), MODULUS - 2)
			differences[end] = normalize((differences[end] - differences[end - 1]) * inverse)
		}
		newton[order] = differences[order]
	}

	coefficients: Result_Coefficients
	basis: Basis_Coefficients
	basis[0] = 1
	degree := 0
	for order := 0; order < n; order += 1 {
		for k := 0; k <= degree; k += 1 {
			coefficients[k] = (coefficients[k] + newton[order] * basis[k]) % MODULUS
		}
		if order + 1 == n do break
		expanded: Basis_Coefficients
		for k := 0; k <= degree; k += 1 {
			expanded[k] = normalize(expanded[k] - basis[k] * points[order])
			expanded[k + 1] = normalize(expanded[k + 1] + basis[k])
		}
		for k := 0; k <= degree + 1; k += 1 { basis[k] = expanded[k] }
		degree += 1
	}
	for i := 0; i < n; i += 1 { store_le(output, 8 * i, coefficients[i]) }
	return i64(bytes)
}
