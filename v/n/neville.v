module neville

@[export: 'neville']
pub fn neville(values &i64, length usize) f64 {
	invalid := -1.0e300
	if length < 4 || length > 34 { return invalid }
	count := unsafe { values[0] }
	target_i := unsafe { values[1] }
	if count < 1 || count > 16 || length != usize(2 * count + 2) || target_i < -1_000_000 || target_i > 1_000_000 { return invalid }
	mut x := []f64{len: 16}
	mut p := []f64{len: 16}
	for i in 0 .. int(count) {
		xi := unsafe { values[2 + 2 * i] }
		yi := unsafe { values[3 + 2 * i] }
		if xi < -1_000_000 || xi > 1_000_000 || yi < -1_000_000 || yi > 1_000_000 { return invalid }
		for j in 0 .. i { if unsafe { values[2 + 2 * j] } == xi { return invalid } }
		x[i] = f64(xi); p[i] = f64(yi)
	}
	target := f64(target_i)
	for k in 1 .. int(count) {
		for i in 0 .. int(count) - k { p[i] = ((target - x[i+k]) * p[i] + (x[i] - target) * p[i+1]) / (x[i] - x[i+k]) }
	}
	return p[0]
}
