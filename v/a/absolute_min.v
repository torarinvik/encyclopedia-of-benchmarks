module absolute_min

const max_values = 256
const max_input_values = max_values + 1

fn magnitude(value i64) i64 {
	if value < 0 { return -value }
	return value
}

fn select_absolute(values &i64, length usize, choose_max bool) i64 {
	value_limit := i64(1_000_000_000)
	if length < 2 || length > max_input_values { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 1 || count_value > max_values || int(length) != int(count_value) + 1 { return -1 }
	for index in 1 .. int(length) {
		value := unsafe { values[index] }
		if value < -value_limit || value > value_limit { return -1 }
	}
	mut best := unsafe { values[1] }
	for index in 2 .. int(length) {
		candidate := unsafe { values[index] }
		if (choose_max && magnitude(candidate) > magnitude(best)) ||
			(choose_max && magnitude(candidate) == magnitude(best) && candidate > best) ||
			(!choose_max && magnitude(candidate) < magnitude(best)) ||
			(!choose_max && magnitude(candidate) == magnitude(best) && candidate < best) {
			best = candidate
		}
	}
	return best
}

@[export: 'absolute_min_benchmark']
pub fn absolute_min_benchmark(values &i64, length usize) i64 {
	return select_absolute(values, length, false)
}
