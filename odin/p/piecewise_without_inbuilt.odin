package piecewise_without_inbuilt

import "core:c"
import "core:math"

@(export)
piecewise_without_inbuilt :: proc "c" (input: [^]f64, input_len: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_len != c.size_t(1) do return -1
	x := input[0]
	if math.isnan_f64(x) || x < -10.0 || x > 10.0 do return -1

	y := f64(1.0)
	if x <= -0.5 {
		y = 0.0
	} else if x < 0.5 {
		y = x
	}

	if output == nil || output_capacity < c.size_t(1) do return -2
	output[0] = y
	return 1
}
