package newton_divided_difference_interpolation

import "core:c"

MODULUS :: i64(998244353)
MAX_NODES :: 12
MAX_LENGTH :: 27

mod_pow :: proc(base_value, exponent_value: i64) -> i64 {
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

@(export)
newton_divided_difference_interpolation :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > c.size_t(MAX_LENGTH) do return -1
	if input[0] < 1 || input[0] > MAX_NODES do return -1
	count := int(input[0])
	if length != c.size_t(2 + 2 * count) do return -1
	nodes: [MAX_NODES]i64
	differences: [MAX_NODES]i64
	for i := 0; i < count; i += 1 {
		nodes[i] = input[1+i]
		differences[i] = input[1+count+i]
		if nodes[i] < 0 || nodes[i] >= MODULUS || differences[i] < 0 || differences[i] >= MODULUS do return -1
		for j := 0; j < i; j += 1 {
			if nodes[i] == nodes[j] do return -1
		}
	}
	query := input[length-1]
	if query < 0 || query >= MODULUS do return -1
	for order := 1; order < count; order += 1 {
		for offset := 0; offset < count-order; offset += 1 {
			i := count - 1 - offset
			numerator := differences[i] - differences[i-1]
			if numerator < 0 do numerator += MODULUS
			denominator := nodes[i] - nodes[i-order]
			if denominator < 0 do denominator += MODULUS
			differences[i] = numerator * mod_pow(denominator, MODULUS-2) % MODULUS
		}
	}
	result := differences[count-1]
	for offset := 0; offset < count-1; offset += 1 {
		i := count - 2 - offset
		factor := query - nodes[i]
		if factor < 0 do factor += MODULUS
		result = (result * factor + differences[i]) % MODULUS
	}
	return result
}
