package mibench_lame_mdct_long

import "core:c"
import "core:math"

INPUT_COUNT :: 18
MAX_INPUT_LENGTH :: c.size_t(19)
OUTPUT_COUNT :: 18
PI :: 3.14159265358979323846264338327950288

@(export)
mibench_lame_mdct_long :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	for k := 0; k < int(input_length); k += 1 {
		value := input[k]
		if value != value || value < -16.0 || value > 16.0 do return -1
	}
	if input_length != c.size_t(INPUT_COUNT) do return -1

	staged: [OUTPUT_COUNT]f64
	for m := 0; m < OUTPUT_COUNT; m += 1 {
		sum: f64 = 0
		for k := 0; k < INPUT_COUNT; k += 1 {
			offset := 38
			if k >= 9 do offset = 74
			angle := PI * f64(2*m+1) * f64(4*k+offset) / 144.0
			sum += input[k] * math.cos_f64(angle)
		}
		staged[m] = (4.0 / 36.0) * sum
	}
	if output == nil || output_capacity < c.size_t(OUTPUT_COUNT) do return -2
	for m := 0; m < OUTPUT_COUNT; m += 1 { output[m] = staged[m] }
	return OUTPUT_COUNT
}
