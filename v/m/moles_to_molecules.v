module moles_to_molecules

import math

const invalid_result = -1.0e300

fn parse_scientific_four(value f64) f64 {
	if value == 0.0 { return 0.0 }
	mut normalized := value
	mut decimal_exponent := 0
	for normalized >= 10.0 { normalized /= 10.0; decimal_exponent++ }
	for normalized < 1.0 { normalized *= 10.0; decimal_exponent-- }
	bits := math.f64_bits(value)
	fraction := bits & ((u64(1) << 52) - 1)
	exponent_bits := int((bits >> 52) & 0x7ff)
	significand := (u64(1) << 52) | fraction
	binary_exponent := exponent_bits - 1023 - 52
	decimal_shift := decimal_exponent - 4
	mut denominator := u64(1)
	for _ in 0 .. decimal_shift { denominator *= 5 }
	binary_shift := binary_exponent - decimal_shift
	mut numerator := significand
	if binary_shift >= 0 { numerator <<= u32(binary_shift) } else { denominator <<= u32(-binary_shift) }
	mut rounded := numerator / denominator
	remainder := numerator % denominator
	if remainder * 2 > denominator || (remainder * 2 == denominator && rounded & 1 != 0) { rounded++ }
	mut decimal_scale := 1.0
	for _ in 0 .. decimal_shift { decimal_scale *= 10.0 }
	return f64(rounded) * decimal_scale
}

@[export: 'moles_to_molecules']
pub fn moles_to_molecules(input &i64, length usize) f64 {
	if unsafe { input == nil } || length != 1 { return invalid_result }
	unsafe {
		moles_micro := input[0]
		if moles_micro < 0 || moles_micro > 2_000_000 { return invalid_result }
		moles := f64(moles_micro) / 1_000_000.0
		return parse_scientific_four(moles * 6.022e23)
	}
}
