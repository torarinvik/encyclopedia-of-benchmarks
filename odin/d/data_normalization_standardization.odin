package data_normalization_standardization

import "core:c"
import "core:math"

Max_Sample_Count :: 128

put_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
data_normalization_standardization :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > c.size_t(Max_Sample_Count + 2) do return -1
	mode := values[0]
	count_arg := values[1]
	if (mode != 0 && mode != 1) || count_arg < 2 || count_arg > Max_Sample_Count ||
		length != c.size_t(count_arg + 2) do return -1
	count := int(count_arg)
	minimum := values[2]
	maximum := values[2]
	sum := f64(0)
	for index := 0; index < count; index += 1 {
		value := values[index + 2]
		if value < -100000 || value > 100000 do return -1
		if value < minimum do minimum = value
		if value > maximum do maximum = value
		sum += f64(value)
	}
	if minimum == maximum do return -1
	output_bytes := c.size_t(count * 8)
	if output == nil || capacity < output_bytes do return -2
	if mode == 0 {
		span := f64(maximum - minimum)
		for index := 0; index < count; index += 1 {
			normalized := f64(values[index + 2] - minimum) / span
			put_f64_le(output, index * 8, normalized)
		}
	} else {
		mean := sum / f64(count)
		squared_deviations := f64(0)
		for index := 0; index < count; index += 1 {
			deviation := f64(values[index + 2]) - mean
			squared_deviations += deviation * deviation
		}
		sample_deviation := math.sqrt(squared_deviations / f64(count - 1))
		for index := 0; index < count; index += 1 {
			standardized := (f64(values[index + 2]) - mean) / sample_deviation
			put_f64_le(output, index * 8, standardized)
		}
	}
	return i64(output_bytes)
}
