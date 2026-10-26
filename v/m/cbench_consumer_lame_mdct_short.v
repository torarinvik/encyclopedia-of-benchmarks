module cbench_consumer_lame_mdct_short

import math

const pi = 3.14159265358979323846264338327950288
const enwindow_max = 0.030526638

@[export: 'cbench_consumer_lame_mdct_short']
fn cbench_consumer_lame_mdct_short(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length == 0 || input_length > 19 { return -1 }
		for k in 0 .. input_length {
			value := input[k]
			if !value.is_finite() || value < -32768.0 || value > 32768.0 { return -1 }
		}
		if input_length != 18 { return -1 }
		mut coefficients := [36]f64{}
		scale := 4.0 / 12.0
		for i in 0 .. 3 {
			w2 := math.cos(pi / 12.0 * (f64(i) + 0.5)) * enwindow_max / 32768.0 * scale
			for m in 0 .. 6 {
				coefficients[6 * m + i] = w2 * math.cos((pi / 48.0) * f64(2 * m + 1) * f64(4 * i + 14))
				coefficients[6 * m + i + 3] = w2 * math.cos((pi / 48.0) * f64(2 * m + 1) * f64(4 * i + 38))
			}
		}
		mut staged := [18]f64{}
		for m in 0 .. 6 {
			for l in 0 .. 3 {
				base := 6 * (2 - l)
				row := 5 - m
				total := coefficients[6 * row] * input[base]
				for i in 1 .. 6 { total += coefficients[6 * row + i] * input[base + i] }
				staged[3 * row + (2 - l)] = total
			}
		}
		if output == nil || output_capacity < 18 { return -2 }
		for i in 0 .. 18 { output[i] = staged[i] }
		return 18
	}
}
