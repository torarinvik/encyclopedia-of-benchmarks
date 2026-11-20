package fornberg_finite_difference_weights

import "core:c"

MODULUS :: i64(998244353)
MAX_INPUT_LENGTH :: 12
MAX_NODES :: 8

mod_norm :: proc "contextless" (value: i64) -> i64 {
	result := value % MODULUS
	return if result < 0 { result + MODULUS } else { result }
}

mod_pow :: proc "contextless" (base_value, exponent_value: i64) -> i64 {
	base, exponent, result := base_value, exponent_value, i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % MODULUS
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := transmute(u64)value
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
fornberg_finite_difference_weights :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
	n_value, order, target := input[0], input[1], input[2]
	if n_value < 1 || n_value > MAX_NODES || order < 0 || order > 3
		|| order >= n_value || i64(length) != n_value + 3 do return -1
	n := int(n_value)
	if target < 0 || target >= MODULUS do return -1
	for index := 0; index < n; index += 1 {
		node := input[3+index]
		if node < 0 || node >= MODULUS do return -1
		for previous := 0; previous < index; previous += 1 {
			if node == input[3+previous] do return -1
		}
	}

	table: [8][4]i64 = {}
	table[0][0] = 1
	previous_product := i64(1)
	for new_index := 1; new_index < n; new_index += 1 {
		old_last: [4]i64
		for derivative := 0; derivative < 4; derivative += 1 {
			old_last[derivative] = table[new_index-1][derivative]
		}
		product := i64(1)
		node := input[3+new_index]
		factor := mod_norm(node - target)
		max_derivative := min(new_index, int(order))
		for old_index := 0; old_index < new_index; old_index += 1 {
			difference := mod_norm(node - input[3+old_index])
			product = product * difference % MODULUS
			inverse_difference := mod_pow(difference, MODULUS-2)
			for derivative := max_derivative; derivative >= 0; derivative -= 1 {
				lower := i64(0)
				if derivative > 0 do lower = table[old_index][derivative-1]
				numerator := mod_norm(factor*table[old_index][derivative] - i64(derivative)*lower)
				table[old_index][derivative] = numerator * inverse_difference % MODULUS
			}
		}
		product_inverse := mod_pow(product, MODULUS-2)
		last_factor := mod_norm(input[2+new_index] - target)
		for derivative := 0; derivative <= max_derivative; derivative += 1 {
			lower := i64(0)
			if derivative > 0 do lower = old_last[derivative-1]
			numerator := mod_norm(i64(derivative)*lower - last_factor*old_last[derivative])
			table[new_index][derivative] = previous_product*product_inverse % MODULUS*numerator % MODULUS
		}
		previous_product = product
	}

	required := c.size_t(8 * (n + 1))
	if output == nil || capacity < required do return -2
	store_i64_le(output, 0, n_value)
	for index := 0; index < n; index += 1 {
		store_i64_le(output, c.size_t(8*(index+1)), table[index][int(order)])
	}
	return i64(required)
}
