module present_value

import math
const invalid_result = -1.0e300

fn round_two_python(value f64) f64 {
	if value == 0.0 { return value }
	negative := value < 0.0
	mut normalized := if negative { -value } else { value }
	mut exponent := 0
	for normalized >= 1.0 { normalized *= 0.5; exponent++ }
	for normalized < 0.5 { normalized *= 2.0; exponent-- }
	significand := u64(normalized * 9_007_199_254_740_992.0)
	numerator := significand * u64(100)
	shift := 53 - exponent
	mut cents := u64(0)
	if shift < 0 { cents = numerator << u32(-shift) }
	else if shift == 0 { cents = numerator }
	else if shift < 64 {
		denominator := u64(1) << u32(shift)
		cents = numerator >> u32(shift)
		remainder := numerator & (denominator - 1)
		half := denominator >> 1
		if remainder > half || (remainder == half && (cents & u64(1)) != 0) { cents++ }
	}
	rounded := f64(cents) / 100.0
	if negative { return -rounded }
	return rounded
}

@[export: 'present_value']
pub fn present_value(values &i64, length usize) f64 {
	if length < 3 || length > 10 { return invalid_result }
	unsafe {
		if values == nil { return invalid_result }
		count_value := values[0]
		rate_ppm := values[1]
		if count_value < 1 || count_value > 8 || length != usize(2 + count_value) || rate_ppm != 0 && rate_ppm != 1_000_000 { return invalid_result }
		count := int(count_value)
		for i in 0 .. count { if values[i + 2] < -1_000_000 || values[i + 2] > 1_000_000 || values[i + 2] % 125 != 0 { return invalid_result } }
		rate := f64(rate_ppm) / 1_000_000.0
		mut total := 0.0
		for i in 0 .. count {
			flow := f64(values[i + 2]) / 1000.0
			total += flow / math.pow(1.0 + rate, f64(i))
		}
		return round_two_python(total)
	}
}
