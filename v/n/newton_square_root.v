module newton_square_root

import math

@[export: 'newton_square_root']
pub fn newton_square_root(value i64) i64 {
	if value < 0 || value > 4611686018427387903 { return -1 }
	if value == 0 { return 0 }

	bit_length := int(math.ceil(math.log2(f64(value))))
	mut root := i64(1) << (bit_length / 2)
	for !(value >= root * root && value <= root * root + root + root) {
		root += value / root
		root /= 2
	}
	return root
}
