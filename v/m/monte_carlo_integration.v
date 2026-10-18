module monte_carlo_integration

const max_n = i64(16)
const min_bound = i64(-10_000_000)
const max_bound = i64(10_000_000)
const max_uniform = i64(999_999)
const invalid_result = -1.0e300

@[export: 'monte_carlo_integration']
pub fn monte_carlo_integration(packed &i64, length usize) f64 {
	if unsafe { packed == nil } || length < 3 || length > 12 { return invalid_result }
	n := unsafe { packed[2] }
	if n < 1 || n > max_n || length != usize(3 + (n + 1) / 2) { return invalid_result }
	a_raw := unsafe { packed[0] }
	b_raw := unsafe { packed[1] }
	if a_raw < min_bound || a_raw > max_bound || b_raw < min_bound || b_raw > max_bound || a_raw >= b_raw { return invalid_result }
	for index in 3 .. length {
		draw := unsafe { packed[index] }
		if draw < 0 || draw > max_uniform { return invalid_result }
	}

	a := f64(a_raw) / 1_000_000.0
	b := f64(b_raw) / 1_000_000.0
	interval := b - a
	mut total := 0.0
	for index in 0 .. int(n / 2) {
		u := f64(unsafe { packed[3 + index] }) / 1_000_000.0
		x1 := a + u * interval
		x2 := a + (1.0 - u) * interval
		total += x1 * x1
		total += x2 * x2
	}
	if n % 2 == 1 {
		u := f64(unsafe { packed[3 + int(n / 2)] }) / 1_000_000.0
		x := a + u * interval
		total += x * x
	}
	return interval * total / f64(n)
}
