module square_root

// Newton square root using binary64 arithmetic and a portable initial estimate.
@[export: 'square_root']
pub fn square_root(value f64) f64 {
	if value == 0.0 { return 0.0 }
	mut estimate := if value >= 1.0 { value } else { 1.0 }
	for _ in 0 .. 1100 {
		next := 0.5 * estimate + 0.5 * (value / estimate)
		if next >= estimate { return estimate }
		estimate = next
	}
	return estimate
}
