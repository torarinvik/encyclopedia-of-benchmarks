module problem7

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut factor := i64(2)
	for factor <= value / factor {
		if value % factor == 0 { return false }
		factor++
	}
	return true
}

@[export: 'problem7']
pub fn problem7(index i64) i64 {
	if index < 1 || index > 10_001 { return -1 }
	mut count := i64(0)
	mut candidate := i64(1)
	for count < index {
		candidate++
		if is_prime(candidate) { count++ }
	}
	return candidate
}
