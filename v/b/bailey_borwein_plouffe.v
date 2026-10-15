module bailey_borwein_plouffe

import math

// Return the source's extracted hexadecimal digit as a numeric nibble.
fn modular_power_16(mut exponent i64, modulus i64) i64 {
	mut result := i64(1) % modulus
	mut base := i64(16) % modulus
	for exponent > 0 {
		if (exponent & 1) != 0 { result = (result * base) % modulus }
		base = (base * base) % modulus
		exponent >>= 1
	}
	return result
}

fn bbp_subsum(position i64, addend i64) f64 {
	mut total := 0.0
	mut index := i64(0)
	for index < position + 1000 {
		denominator := 8 * index + addend
		exponent := position - 1 - index
		term := if index < position {
			f64(modular_power_16(exponent, denominator)) / f64(denominator)
		} else {
			math.pow(16.0, f64(exponent)) / f64(denominator)
		}
		total += term
		index++
	}
	return total
}

@[export: 'bailey_borwein_plouffe']
pub fn bailey_borwein_plouffe(position i64) i64 {
	if position < 1 || position > 10 { return -1 }
	sum_result := 4.0 * bbp_subsum(position, 1) - 2.0 * bbp_subsum(position, 4)
		- bbp_subsum(position, 5) - bbp_subsum(position, 6)
	fractional := sum_result - math.floor(sum_result)
	return i64(fractional * 16.0)
}
