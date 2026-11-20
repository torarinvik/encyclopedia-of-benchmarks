package barycentric_lagrange_evaluation

import "core:c"

MODULUS :: i64(998244353)
MAX_INPUT_LENGTH :: 19
MAX_NODES :: 8

mod_pow :: proc "contextless" (base_value, exponent_value: i64) -> i64 {
	base, exponent, result := base_value, exponent_value, i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % MODULUS
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

@(export)
barycentric_lagrange_evaluation :: proc "c" (input: [^]i64,
	length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
	count_value := input[0]
	if count_value < 1 || count_value > MAX_NODES do return -1
	count := int(count_value)
	if int(length) != 2*count+2 do return -1
	for index := 1; index < int(length); index += 1 {
		if input[index] < 0 || input[index] >= MODULUS do return -1
	}
	for left := 0; left < count; left += 1 {
		for right := 0; right < left; right += 1 {
			if input[1+left] == input[1+right] do return -1
		}
	}

	weights: [8]i64 = {}
	for index := 0; index < count; index += 1 {
		product := i64(1)
		node := input[1+index]
		for other := 0; other < count; other += 1 {
			if other == index do continue
			difference := (node-input[1+other]+MODULUS) % MODULUS
			product = product*difference % MODULUS
		}
		weights[index] = mod_pow(product, MODULUS-2)
	}

	ordinate_start := 1+count
	query := input[2*count+1]
	for index := 0; index < count; index += 1 {
		if query == input[1+index] do return input[ordinate_start+index]
	}
	numerator := i64(0)
	denominator := i64(0)
	for index := 0; index < count; index += 1 {
		difference := (query-input[1+index]+MODULUS) % MODULUS
		term := weights[index]*mod_pow(difference, MODULUS-2) % MODULUS
		numerator = (numerator+term*input[ordinate_start+index]) % MODULUS
		denominator = (denominator+term) % MODULUS
	}
	if denominator == 0 do return -1
	return numerator*mod_pow(denominator, MODULUS-2) % MODULUS
}
