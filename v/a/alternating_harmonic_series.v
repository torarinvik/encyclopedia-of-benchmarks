module alternating_harmonic_series

const max_count = 1000

// Check whether each rational input approximates its canonical alternating term.
@[export: 'alternating_harmonic_series']
pub fn alternating_harmonic_series(input &i64, length usize) i64 {
	if length < 1 { return -1 }
	count := unsafe { input[0] }
	if count < 0 || count > max_count || length != usize(1 + 2 * count) { return -1 }
	for index in 0 .. int(count) {
		numerator := unsafe { input[1 + 2 * index] }
		denominator := unsafe { input[2 + 2 * index] }
		if numerator < -1000 || numerator > 1000 || denominator < 1 || denominator > 1000 { return -1 }
		sign := i64(1)
		if index % 2 == 1 { sign = -1 }
		delta := numerator * (index + 1) - sign * denominator
		if delta < 0 { delta = -delta }
		if delta * 1_000_000_000 > denominator * (index + 1) { return 0 }
	}
	return 1
}
