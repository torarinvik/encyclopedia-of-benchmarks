module light_aberration

import math

const invalid_result = -1.0e300

fn round_five_even(value f64) f64 {
	scaled := value * 100000.0
	fraction := scaled - math.floor(scaled)
	if math.abs(fraction - 0.5) <= 1.0e-7 { return invalid_result }
	if value == 0.0 { return value }
	negative := value < 0.0
	mut normalized := math.abs(value)
	mut exponent := 0
	for normalized < 1.0 { normalized *= 2.0; exponent-- }
	for normalized >= 2.0 { normalized *= 0.5; exponent++ }
	mantissa := u64(normalized * 4503599627370496.0)
	shift := 52 - exponent
	if shift > 70 { return if negative { -0.0 } else { 0.0 } }
	low_product := (mantissa & 0xffffffff) * 100000
	high_product := (mantissa >> 32) * 100000
	shifted_high := high_product << 32
	low := low_product +% shifted_high
	high := (high_product >> 32) + u64(low < low_product)
	quotient := if shift < 64 { (low >> u64(shift)) | (high << u64(64 - shift)) } else { high >> u64(shift - 64) }
	half_bit := if shift - 1 < 64 { (low >> u64(shift - 1)) & 1 } else { (high >> u64(shift - 65)) & 1 }
	lower_bits := if shift - 1 < 64 { (low & ((u64(1) << u64(shift - 1)) - 1)) != 0 }
		else { low != 0 || (high & ((u64(1) << u64(shift - 65)) - 1)) != 0 }
	rounded := quotient + u64(half_bit != 0 && (lower_bits || (quotient & 1) != 0))
	result := f64(rounded) / 100000.0
	return if negative { -result } else { result }
}

@[export: 'light_aberration']
pub fn light_aberration(values &i64, length usize) f64 {
	if length != 2 || unsafe { values == nil } { return invalid_result }
	unsafe {
		theta_code := values[0]
		beta_code := values[1]
		if theta_code < -3141592 || theta_code > 3141592 || beta_code < 0 || beta_code > 999999 { return invalid_result }
		theta := f64(theta_code) / 1000000.0
		beta := f64(beta_code) / 1000000.0
		factor := math.sqrt((1.0 - beta) / (1.0 + beta))
		angle := 2.0 * math.atan(factor * math.tan(theta / 2.0))
		return round_five_even(angle)
	}
}
