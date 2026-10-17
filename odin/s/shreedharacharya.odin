package shreedharacharya

import "core:c"
import "core:math"

MAX_COEFFICIENT :: 1_000_000.0
MIN_ABS_LEADING_COEFFICIENT :: 0.000001

@(export)
shreedharacharya :: proc "c" (input: [^]f64, input_len: c.size_t,
		output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_len != 3 do return -1
	a, b, c_value := input[0], input[1], input[2]
	if a != a || b != b || c_value != c_value ||
		a < -MAX_COEFFICIENT || a > MAX_COEFFICIENT ||
		(a > -MIN_ABS_LEADING_COEFFICIENT && a < MIN_ABS_LEADING_COEFFICIENT) ||
		b < -MAX_COEFFICIENT || b > MAX_COEFFICIENT ||
		c_value < -MAX_COEFFICIENT || c_value > MAX_COEFFICIENT do return -1

	discriminant := b*b - 4.0*a*c_value
	var roots: [2]f64
	count := c.size_t(0)
	if discriminant == 0.0 {
		roots[count] = -b / (2.0 * a)
		count += 1
	} else if discriminant > 0.0 {
		square_root := math.sqrt(discriminant)
		denominator := 2.0 * a
		roots[count] = (-b + square_root) / denominator
		count += 1
		roots[count] = (-b - square_root) / denominator
		count += 1
	}
	for index in 0..<count {
		if roots[index] != roots[index] do return -1
	}
	if output == nil || output_capacity < count do return -2
	for index in 0..<count { output[index] = roots[index] }
	return i64(count)
}
