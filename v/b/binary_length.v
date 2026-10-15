module binary_length

import math

@[export: 'binary_length']
pub fn binary_length(value i64) i64 {
	if value <= 0 || value > 2147483647 { return -1 }
	return i64(math.floor(math.log2(f64(value)))) + 1
}
