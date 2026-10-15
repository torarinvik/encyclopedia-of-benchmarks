package binary_length

import "core:math"

@(export)
binary_length :: proc "c" (value: i64) -> i64 {
	if value <= 0 || value > 2147483647 do return -1
	return i64(math.floor_f64(math.log2_f64(f64(value)))) + 1
}
