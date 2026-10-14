module hamming_distance

// Portable Hamming distance over two unsigned 64-bit values.
@[export: 'hamming_distance']
pub fn hamming_distance(left u64, right u64) i64 {
	mut left_bits := left
	mut right_bits := right
	mut count := i64(0)
	for left_bits != 0 || right_bits != 0 {
		if (left_bits & u64(1)) != (right_bits & u64(1)) { count++ }
		left_bits >>= 1
		right_bits >>= 1
	}
	return count
}
