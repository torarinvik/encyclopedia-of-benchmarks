module hamming_distance

import math.bits

@[export: 'hamming_distance']
pub fn hamming_distance(left u64, right u64) i64 {
	return i64(bits.ones_count_64(left ^ right))
}
