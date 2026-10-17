package moles_to_molecules

import "core:c"

INVALID_RESULT :: -1.0e300

parse_scientific_four :: proc "contextless" (value: f64) -> f64 {
	if value == 0.0 do return 0.0
	normalized := value
	decimal_exponent := 0
	for normalized >= 10.0 { normalized /= 10.0; decimal_exponent += 1 }
	for normalized < 1.0 { normalized *= 10.0; decimal_exponent -= 1 }
	bits := transmute(u64)value
	fraction := bits & ((u64(1) << 52) - 1)
	exponent_bits := int((bits >> 52) & 0x7ff)
	significand := (u64(1) << 52) | fraction
	binary_exponent := exponent_bits - 1023 - 52
	decimal_shift := decimal_exponent - 4
	denominator := u64(1)
	for index in 0 ..< decimal_shift { denominator *= 5 }
	binary_shift := binary_exponent - decimal_shift
	numerator := significand
	if binary_shift >= 0 { numerator <<= u64(binary_shift) } else { denominator <<= u64(-binary_shift) }
	rounded := numerator / denominator
	remainder := numerator % denominator
	if remainder * 2 > denominator || (remainder * 2 == denominator && (rounded & 1) != 0) { rounded += 1 }
	decimal_scale := 1.0
	for index in 0 ..< decimal_shift { decimal_scale *= 10.0 }
	return f64(rounded) * decimal_scale
}

moles_to_molecules :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length != 1 do return INVALID_RESULT
	moles_micro := input[0]
	if moles_micro < 0 || moles_micro > 2_000_000 do return INVALID_RESULT
	moles := f64(moles_micro) / 1_000_000.0
	return parse_scientific_four(moles * 6.022e23)
}
