package problem45

integer_sqrt :: proc(value: i64) -> i64 {
	low: i64 = 0
	high: i64 = 200_000
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
problem45 :: proc "c" (start: i64) -> i64 {
	if start < 0 || start > 27_693 { return -1 }
	for index := start; index <= 27_693; index += 1 {
		value := index * (2 * index - 1)
		if is_pentagonal(value) { return value }
	}
	return -1
}
