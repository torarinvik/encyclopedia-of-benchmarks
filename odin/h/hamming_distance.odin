package hamming_distance

import "core:math/bits"

@(export)
hamming_distance :: proc "c" (left, right: u64) -> i64 {
	return i64(bits.count_ones(left ~ right))
}
