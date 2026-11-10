module count_leading_zeros

import math.bits

@[export: 'count_leading_zeros']
pub fn count_leading_zeros(value i64) i64 {
	if value < -2147483648 || value > 2147483647 { return -1 }
	return i64(bits.leading_zeros_32(u32(value)))
}
