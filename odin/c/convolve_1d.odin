package convolve_1d

import "core:c"

MAX_SIGNAL_LENGTH :: 64
MAX_INPUT_LENGTH :: 2 + 2 * MAX_SIGNAL_LENGTH
MAX_OUTPUT_BYTES :: MAX_SIGNAL_LENGTH * 8
MAX_FIXED_SAMPLE :: i64(128)
SAMPLE_SCALE :: 16.0

write_f64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + c.size_t(byte)] = u8(bits >> u64(8 * byte))
	}
}

@(export)
convolve_1d :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	raw_signal_count, raw_kernel_count := input[0], input[1]
	if raw_signal_count < 0 || raw_signal_count > i64(MAX_SIGNAL_LENGTH) ||
		raw_kernel_count < 0 || raw_kernel_count > i64(MAX_SIGNAL_LENGTH) do return -1
	signal_count, kernel_count := int(raw_signal_count), int(raw_kernel_count)
	if length != c.size_t(2 + signal_count + kernel_count) do return -1
	for index := 0; index < signal_count + kernel_count; index += 1 {
		value := input[index + 2]
		if value < -MAX_FIXED_SAMPLE || value > MAX_FIXED_SAMPLE do return -1
	}

	output_bytes := signal_count * 8
	if output_capacity < c.size_t(output_bytes) || (output_bytes > 0 && output == nil) do return -2
	center := kernel_count / 2
	for i := 0; i < signal_count; i += 1 {
		accumulated := 0.0
		for j := 0; j < kernel_count; j += 1 {
			signal_index := i + j - center
			if signal_index >= 0 && signal_index < signal_count {
				kernel_value := f64(input[2 + signal_count + j]) / SAMPLE_SCALE
				signal_value := f64(input[2 + signal_index]) / SAMPLE_SCALE
				accumulated += kernel_value * signal_value
			}
		}
		write_f64_le(output, c.size_t(i * 8), accumulated)
	}
	return i64(output_bytes)
}
