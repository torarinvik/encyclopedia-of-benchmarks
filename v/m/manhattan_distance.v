module manhattan_distance

@[export: 'manhattan_distance']
pub fn manhattan_distance(values &i64, length usize) f64 {
	if length < 3 { return -1.0e300 }
	dimensions := unsafe { values[0] }
	if dimensions < 1 || dimensions > 16 || length != 1 + 2 * usize(dimensions) { return -1.0e300 }
	mut total := i64(0)
	for index := usize(0); index < usize(dimensions); index++ {
		first := unsafe { values[1 + index] }
		second := unsafe { values[1 + usize(dimensions) + index] }
		if first < -1_000_000 || first > 1_000_000 || second < -1_000_000 || second > 1_000_000 { return -1.0e300 }
		difference := first - second
		if difference < 0 { total -= difference } else { total += difference }
	}
	return f64(total)
}
