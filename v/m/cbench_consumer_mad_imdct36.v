module cbench_consumer_mad_imdct36

import math

const input_count = 18
const max_input_length = 19
const output_count = 36
const pi = 3.14159265358979323846264338327950288

@[export: 'cbench_consumer_mad_imdct36']
pub fn cbench_consumer_mad_imdct36(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length == 0 || input_length > max_input_length { return -1 }
		for k in 0 .. input_length {
			value := input[k]
			if !value.is_finite() || value < -16.0 || value > 16.0 { return -1 }
		}
		if input_length != input_count { return -1 }
		mut staged := [output_count]f64{}
		for n in 0 .. output_count {
			mut sum := 0.0
			for k in 0 .. input_count {
				angle := pi * f64(2 * n + 19) * f64(2 * k + 1) / 72.0
				sum += input[k] * math.cos(angle)
			}
			staged[n] = sum
		}
		if output == nil || output_capacity < output_count { return -2 }
		for n in 0 .. output_count { output[n] = staged[n] }
		return output_count
	}
}
