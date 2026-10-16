module convolve_1d

import math

const max_signal_length = 64
const max_input_length = 2 + 2 * max_signal_length
const max_output_bytes = max_signal_length * 8
const max_fixed_sample = i64(128)
const sample_scale = 16.0

fn write_f64_le(mut output &u8, offset usize, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'convolve_1d']
pub fn convolve_1d(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	raw_signal_count := unsafe { input[0] }
	raw_kernel_count := unsafe { input[1] }
	if raw_signal_count < 0 || raw_signal_count > i64(max_signal_length) ||
		raw_kernel_count < 0 || raw_kernel_count > i64(max_signal_length) { return -1 }
	signal_count := int(raw_signal_count)
	kernel_count := int(raw_kernel_count)
	if length != usize(2 + signal_count + kernel_count) { return -1 }
	unsafe {
		for index in 0 .. signal_count + kernel_count {
			value := input[index + 2]
			if value < -max_fixed_sample || value > max_fixed_sample { return -1 }
		}
	}

	output_bytes := signal_count * 8
	if output_capacity < usize(output_bytes) || (output_bytes > 0 && unsafe { output == nil }) { return -2 }
	center := kernel_count / 2
	for i in 0 .. signal_count {
		mut accumulated := 0.0
		for j in 0 .. kernel_count {
			signal_index := i + j - center
			if signal_index >= 0 && signal_index < signal_count {
				unsafe {
					kernel_value := f64(input[2 + signal_count + j]) / sample_scale
					signal_value := f64(input[2 + signal_index]) / sample_scale
					accumulated += kernel_value * signal_value
				}
			}
		}
		write_f64_le(mut output, usize(i * 8), accumulated)
	}
	return i64(output_bytes)
}
