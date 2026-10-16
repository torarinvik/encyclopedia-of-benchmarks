module problem58

fn is_prime(value i64) bool {
	if value < 2 { return false }
	if value < 4 { return true }
	if value % 2 == 0 || value % 3 == 0 { return false }
	mut divisor := i64(5)
	for divisor <= value / divisor {
		if value % divisor == 0 || value % (divisor + 2) == 0 { return false }
		divisor += 6
	}
	return true
}

@[export: 'problem58']
pub fn problem58(ratio f64) f64 {
	if !(ratio >= 0.1 && ratio <= 0.6) { return -1.0 }
	mut side := i64(3)
	mut prime_count := i64(3)
	for f64(prime_count) / f64(2 * side - 1) >= ratio {
		square := side * side
		step := side + 1
		if is_prime(square + step) { prime_count++ }
		if is_prime(square + 2 * step) { prime_count++ }
		if is_prime(square + 3 * step) { prime_count++ }
		side += 2
	}
	return f64(side)
}
