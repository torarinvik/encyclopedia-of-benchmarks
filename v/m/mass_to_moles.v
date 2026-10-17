module mass_to_moles

import math

const invalid_result = -1.0e300

fn round_binary64_to_hundredth(value f64) f64 {
	if value == 0.0 { return 0.0 }
	bits := math.f64_bits(value)
	fraction := bits & ((u64(1) << 52) - 1)
	exponent_bits := int((bits >> 52) & 0x7ff)
	significand := (u64(1) << 52) | fraction
	binary_exponent := exponent_bits - 1023 - 52
	shift := u32(-binary_exponent)
	scaled_significand := significand * 100
	denominator := u64(1) << shift
	mut hundredths := scaled_significand >> shift
	remainder := scaled_significand & (denominator - 1)
	halfway := denominator >> 1
	if remainder > halfway || (remainder == halfway && hundredths & 1 != 0) { hundredths++ }
	return f64(hundredths) / 100.0
}

@[export: 'mass_to_moles']
pub fn mass_to_moles(input &i64, length usize) f64 {
	if unsafe { input == nil } || length != 2 { return invalid_result }
	unsafe {
		mass := input[0]
		molar_mass := input[1]
		if mass < 0 || mass > 1000 || molar_mass < 1 || molar_mass > 1000 { return invalid_result }
		return round_binary64_to_hundredth(f64(mass) / f64(molar_mass))
	}
}
