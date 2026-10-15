module babylonian_sqrt

fn absolute(value f64) f64 {
	if value < 0.0 { return -value }
	return value
}

@[export: 'babylonian_sqrt']
pub fn babylonian_sqrt(input f64) f64 {
	if !(input >= 0.0 && input <= 1_000_000.0) { return -1.0 }
	mut estimate := input / 2.0
	tolerance := 0.000001
	for tolerance <= absolute(estimate * estimate - input) {
		estimate = 0.5 * (estimate + input / estimate)
	}
	return estimate
}
