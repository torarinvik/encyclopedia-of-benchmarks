module problem45

fn integer_sqrt(value i64) i64 {
	mut low := i64(0)
	mut high := i64(200_000)
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

@[export: 'problem45']
pub fn problem45(start i64) i64 {
	if start < 0 || start > 27_693 { return -1 }
	mut index := start
	for index <= 27_693 {
		value := index * (2 * index - 1)
		if is_pentagonal(value) { return value }
		index++
	}
	return -1
}
