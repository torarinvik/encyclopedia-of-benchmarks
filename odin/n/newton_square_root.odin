package newton_square_root

import "core:math"

@(export)
newton_square_root :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > 4611686018427387903 do return -1
	if value == 0 do return 0

	bit_length := i32(math.ceil_f64(math.log2_f64(f64(value))))
	root := i64(1) << (bit_length / 2)
	for !(value >= root * root && value <= root * root + root + root) {
		root += value / root
		root /= 2
	}
	return root
}
