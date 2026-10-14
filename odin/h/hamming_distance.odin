package hamming_distance

// Portable Hamming distance over two unsigned 64-bit values.
@(export)
hamming_distance :: proc "c" (left, right: u64) -> i64 {
	left_bits := left
	right_bits := right
	count := i64(0)
	for left_bits != 0 || right_bits != 0 {
		if (left_bits & 1) != (right_bits & 1) do count += 1
		left_bits = left_bits >> 1
		right_bits = right_bits >> 1
	}
	return count
}
