package fibonacci_formula

import "core:math"

@(export)
fibonacci_formula :: proc "c" (input: i64) -> i64 {
	if input < 0 || input > 35 do return -1
	n := u32(input)
	exponent := f64(n + 1)
	seq := f32((1.0 / math.sqrt_f64(5.0) * math.pow_f64((1.0 + math.sqrt_f64(5.0)) / 2.0, exponent))
		- (1.0 / math.sqrt_f64(5.0) * math.pow_f64((1.0 - math.sqrt_f64(5.0)) / 2.0, exponent)))
	return i64(i32(seq))
}
