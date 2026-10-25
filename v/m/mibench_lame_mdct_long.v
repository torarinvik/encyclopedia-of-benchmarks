module mibench_lame_mdct_long

import math

const input_count = 18
const max_input_length = 19
const output_count = 18
const pi = 3.14159265358979323846264338327950288

@[export: 'mibench_lame_mdct_long']
pub fn mibench_lame_mdct_long(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length == 0 || input_length > max_input_length { return -1 }
		for k in 0 .. input_length {
			value := input[k]
			if !value.is_finite() || value < -16.0 || value > 16.0 { return -1 }
		}
		if input_length != input_count { return -1 }
		mut staged := [output_count]f64{}
		for m in 0 .. output_count {
			mut sum := 0.0
			for k in 0 .. input_count {
				offset := if k < 9 { 38 } else { 74 }
				angle := pi * f64(2 * m + 1) * f64(4 * k + offset) / 144.0
				sum += input[k] * math.cos(angle)
			}
			staged[m] = (4.0 / 36.0) * sum
		}
		if output == nil || output_capacity < output_count { return -2 }
		for m in 0 .. output_count { output[m] = staged[m] }
		return output_count
	}
}
