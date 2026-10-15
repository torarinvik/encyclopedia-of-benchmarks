module fibonacci_formula

import math

// Source-ordered Binet formula, rounded to f32 then truncated to i32.
@[export: 'fibonacci_formula']
pub fn fibonacci_formula(input i64) i64 {
	if input < 0 || input > 35 {
		return -1
	}
	n := u32(input)
	exponent := f64(n + 1)
	seq := f32((1.0 / math.sqrt(5.0) * math.pow((1.0 + math.sqrt(5.0)) / 2.0, exponent))
		- (1.0 / math.sqrt(5.0) * math.pow((1.0 - math.sqrt(5.0)) / 2.0, exponent)))
	return i64(i32(seq))
}
