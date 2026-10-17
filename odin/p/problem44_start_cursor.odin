package problem44_start_cursor

pentagonal :: proc(index: i64) -> i64 {
	return index * (3 * index - 1) / 2
}

integer_sqrt :: proc(value: i64) -> i64 {
	low: i64 = 0
	high: i64 = 20_000
	for high - low > 1 {
		middle := (low + high) / 2
		if middle * middle <= value { low = middle } else { high = middle }
	}
	return low
}

is_pentagonal :: proc(value: i64) -> bool {
	discriminant := 24 * value + 1
	root := integer_sqrt(discriminant)
	return root * root == discriminant && (root + 1) % 6 == 0
}

@(export)
problem44_start_cursor :: proc "c" (start: i64) -> i64 {
	if start < 1 || start > 2166 { return -1 }
	for high := start + 1; high <= 2167; high += 1 {
		high_value := pentagonal(high)
		for low := high - 1; low > 0; low -= 1 {
			low_value := pentagonal(low)
			difference := high_value - low_value
		sum := high_value + low_value
			if is_pentagonal(difference) && is_pentagonal(sum) { return difference }
		}
	}
	return -1
}
