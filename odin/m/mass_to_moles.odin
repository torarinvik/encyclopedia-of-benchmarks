package mass_to_moles

import "core:c"

INVALID_RESULT :: -1.0e300

round_binary64_to_hundredth :: proc "contextless" (value: f64) -> f64 {
	if value == 0.0 do return 0.0
	bits := transmute(u64)value
	fraction := bits & ((u64(1) << 52) - 1)
	exponent_bits := int((bits >> 52) & 0x7ff)
	significand := (u64(1) << 52) | fraction
	binary_exponent := exponent_bits - 1023 - 52
	shift := u64(-binary_exponent)
	scaled_significand := significand * 100
	denominator := u64(1) << shift
	hundredths := scaled_significand >> shift
	remainder := scaled_significand & (denominator - 1)
	halfway := denominator >> 1
	if remainder > halfway || (remainder == halfway && (hundredths & 1) != 0) do hundredths += 1
	return f64(hundredths) / 100.0
}

mass_to_moles :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length != 2 do return INVALID_RESULT
	mass, molar_mass := input[0], input[1]
	if mass < 0 || mass > 1000 || molar_mass < 1 || molar_mass > 1000 do return INVALID_RESULT
	return round_binary64_to_hundredth(f64(mass) / f64(molar_mass))
}
