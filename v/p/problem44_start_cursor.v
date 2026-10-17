module problem44_start_cursor

fn pentagonal(index i64) i64 {
	return index * (3 * index - 1) / 2
}

fn integer_sqrt(value i64) i64 {
	mut low := i64(0)
	mut high := i64(20_000)
	for high - low > 1 {
		middle := (low + high) / 2
		if middle * middle <= value { low = middle } else { high = middle }
	}
	return low
}

fn is_pentagonal(value i64) bool {
	discriminant := 24 * value + 1
	root := integer_sqrt(discriminant)
	return root * root == discriminant && (root + 1) % 6 == 0
}

@[export: 'problem44_start_cursor']
pub fn problem44_start_cursor(start i64) i64 {
	if start < 1 || start > 2166 { return -1 }
	mut high := start + 1
	for high <= 2167 {
		high_value := pentagonal(high)
		mut low := high - 1
		for low > 0 {
			low_value := pentagonal(low)
			difference := high_value - low_value
			sum := high_value + low_value
			if is_pentagonal(difference) && is_pentagonal(sum) { return difference }
			low--
		}
		high++
	}
	return -1
}
