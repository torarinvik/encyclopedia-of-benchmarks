module piecewise_without_inbuilt

import math

@[export: 'piecewise_without_inbuilt']
pub fn piecewise_without_inbuilt(input &f64, input_len usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if isnil(input) || input_len != 1 { return -1 }
		x := input[0]
		if math.is_nan(x) || x < -10.0 || x > 10.0 { return -1 }

		mut y := 1.0
		if x <= -0.5 {
			y = 0.0
		} else if x < 0.5 {
			y = x
		}

		if isnil(output) || output_capacity < 1 { return -2 }
		output[0] = y
		return 1
	}
}
