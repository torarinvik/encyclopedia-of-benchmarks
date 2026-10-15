package bailey_borwein_plouffe

import "core:math"

// Return the source's extracted hexadecimal digit as a numeric nibble.
modular_power_16 :: proc(exponent_value, modulus: i64) -> i64 {
	exponent := exponent_value
	result := i64(1) % modulus
	base := i64(16) % modulus
	for exponent > 0 {
		if (exponent & 1) != 0 do result = (result * base) % modulus
		base = (base * base) % modulus
		exponent = exponent >> 1
	}
	return result
}

bbp_subsum :: proc(position, addend: i64) -> f64 {
	total := 0.0
	for index := i64(0); index < position + 1000; index += 1 {
		denominator := 8 * index + addend
		exponent := position - 1 - index
		term := if index < position {
			f64(modular_power_16(exponent, denominator)) / f64(denominator)
		} else {
			math.pow_f64(16.0, f64(exponent)) / f64(denominator)
		}
		total += term
	}
	return total
}

@(export)
bailey_borwein_plouffe :: proc "c" (position: i64) -> i64 {
	if position < 1 || position > 10 do return -1
	sum_result := 4.0 * bbp_subsum(position, 1) - 2.0 * bbp_subsum(position, 4)
		- bbp_subsum(position, 5) - bbp_subsum(position, 6)
	fractional := sum_result - math.floor_f64(sum_result)
	return i64(fractional * 16.0)
}
