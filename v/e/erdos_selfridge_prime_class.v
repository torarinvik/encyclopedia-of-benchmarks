module erdos_selfridge_prime_class

const max_prime = i64(100_000)

fn es_is_prime(value i64) bool {
	if value < 2 { return false }
	if value % 2 == 0 { return value == 2 }
	mut divisor := i64(3)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor += 2
	}
	return true
}

fn es_class_for_prime(prime i64, direction i64) i64 {
	mut remainder := prime + direction
	mut best := i64(1)
	mut divisor := i64(2)
	for divisor <= remainder / divisor {
		if remainder % divisor == 0 {
			if divisor > 3 {
				candidate := i64(1) + es_class_for_prime(divisor, direction)
				if candidate > best { best = candidate }
			}
			for remainder % divisor == 0 {
				remainder /= divisor
			}
		}
		divisor++
	}
	if remainder > 3 {
		candidate := i64(1) + es_class_for_prime(remainder, direction)
		if candidate > best { best = candidate }
	}
	return best
}

@[export: 'erdos_selfridge_prime_class']
pub fn erdos_selfridge_prime_class(values &i64, length usize) i64 {
	if length < 1 || length > 3 || unsafe { values == nil } { return -1 }
	unsafe {
		if length != 2 { return -1 }
		prime := values[0]
		direction := values[1]
		if prime < 2 || prime > max_prime || (direction != -1 && direction != 1) { return -1 }
		if !es_is_prime(prime) { return -1 }
		return es_class_for_prime(prime, direction)
	}
}

