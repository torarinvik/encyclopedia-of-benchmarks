package light_aberration

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300

round_five_even :: proc(value: f64) -> f64 {
	scaled := value * 100000.0
	fraction := scaled - math.floor_f64(scaled)
	if math.abs(fraction - 0.5) <= 1.0e-7 do return INVALID_RESULT
	if value == 0.0 do return value
	negative := value < 0.0
	normalized := math.abs(value)
	exponent := 0
	for normalized < 1.0 { normalized *= 2.0; exponent -= 1 }
	for normalized >= 2.0 { normalized *= 0.5; exponent += 1 }
	mantissa := u64(normalized * 4503599627370496.0)
	shift := 52 - exponent
	if shift > 70 do return if negative then -0.0 else 0.0
	low_product := (mantissa & 0xffffffff) * 100000
	high_product := (mantissa >> 32) * 100000
	shifted_high := high_product << 32
	low := low_product + shifted_high
	carry := u64(0)
	if low < low_product do carry = 1
	high := (high_product >> 32) + carry
	quotient := if shift < 64 { (low >> u64(shift)) | (high << u64(64 - shift)) } else { high >> u64(shift - 64) }
	half_bit := if shift - 1 < 64 { (low >> u64(shift - 1)) & 1 } else { (high >> u64(shift - 65)) & 1 }
	lower_bits := if shift - 1 < 64 { (low & ((u64(1) << u64(shift - 1)) - 1)) != 0 }
		else { low != 0 || (high & ((u64(1) << u64(shift - 65)) - 1)) != 0 }
	increment := u64(0)
	if half_bit != 0 && (lower_bits || (quotient & 1) != 0) do increment = 1
	rounded := quotient + increment
	result := f64(rounded) / 100000.0
	return if negative then -result else result
}

@(export)
light_aberration :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return INVALID_RESULT
	theta_code := values[0]
	beta_code := values[1]
	if theta_code < -3141592 || theta_code > 3141592 || beta_code < 0 || beta_code > 999999 do return INVALID_RESULT
	theta := f64(theta_code) / 1000000.0
	beta := f64(beta_code) / 1000000.0
	factor := math.sqrt_f64((1.0 - beta) / (1.0 + beta))
	angle := 2.0 * math.atan(factor * math.tan(theta / 2.0))
	return round_five_even(angle)
}
