module hamming_distance_bytes

const max_byte_length = i64(1024)

// Count differing byte positions in two equal-length byte strings.
@[export: 'hamming_distance_bytes']
pub fn hamming_distance_bytes(values &i64, length usize) i64 {
	if length < 1 || length > 2050 { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 0 || count_value > max_byte_length ||
		length != usize(1 + 2 * count_value) { return -1 }
	count := int(count_value)
	mut distance := i64(0)
	for index in 0 .. count {
		left := unsafe { values[index + 1] }
		right := unsafe { values[count + index + 1] }
		if left < 0 || left > 255 || right < 0 || right > 255 { return -1 }
		if left != right { distance++ }
	}
	return distance
}
