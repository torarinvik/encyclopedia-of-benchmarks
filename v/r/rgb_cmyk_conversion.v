module main

import math

const output_length = 4

fn round_ties_to_even(value f64) i64 {
	lower := math.floor(value)
	fraction := value - lower
	base := i64(lower)
	if fraction < 0.5 { return base }
	if fraction > 0.5 { return base + 1 }
	if base % 2 == 0 { return base }
	return base + 1
}

@[export: 'rgb_cmyk_conversion']
pub fn rgb_cmyk_conversion(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		for i in 0 .. 3 { if input[i] < 0 || input[i] > 255 { return -1 } }
		if output == nil || capacity < output_length { return -2 }
		red := f64(input[0]) / 255.0
		green := f64(input[1]) / 255.0
		blue := f64(input[2]) / 255.0
		maximum := max(max(red, green), blue)
		key := 1.0 - maximum
		if key == 1.0 { output[0] = 0; output[1] = 0; output[2] = 0; output[3] = 100; return output_length }
		denominator := 1.0 - key
		output[0] = u8(round_ties_to_even(100.0 * (1.0 - red - key) / denominator))
		output[1] = u8(round_ties_to_even(100.0 * (1.0 - green - key) / denominator))
		output[2] = u8(round_ties_to_even(100.0 * (1.0 - blue - key) / denominator))
		output[3] = u8(round_ties_to_even(100.0 * key))
		return output_length
	}
}
