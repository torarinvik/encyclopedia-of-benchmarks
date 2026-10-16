package julia_sets

import "core:c"

put_f32 :: proc "contextless" (output: [^]u8, offset: int, value: f32) {
	bits := transmute(u32)value
	for byte := 0; byte < 4; byte += 1 {
		output[offset+byte] = u8(bits >> u32(8*byte))
	}
}

@(export)
julia_sets :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 68 do return -1
	iterations, cr_units, ci_units, count_value := input[0], input[1], input[2], input[3]
	if iterations < 0 || iterations > 8 || count_value < 0 || count_value > 32 do return -1
	if cr_units < -128 || cr_units > 128 || ci_units < -128 || ci_units > 128 do return -1
	count := int(count_value)
	if int(length) != 4 + 2*count do return -1
	for index := 0; index < 2*count; index += 1 {
		if input[4+index] < -128 || input[4+index] > 128 do return -1
	}
	needed := 8*count
	if output == nil || capacity < c.size_t(needed) do return -2

	cr := f32(cr_units) / 16.0
	ci := f32(ci_units) / 16.0
	computed: [64]f32
	for point := 0; point < count; point += 1 {
		real := f32(input[4+2*point]) / 16.0
		imag := f32(input[5+2*point]) / 16.0
		for step: i64 = 0; step < iterations; step += 1 {
			real_square := real * real
			imag_square := imag * imag
			real_imag := real * imag
			imag_real := imag * real
			next_real := (real_square-imag_square)+cr
			next_imag := (real_imag+imag_real)+ci
			if !(next_real == next_real && next_real <= 3.402823466e38 && next_real >= -3.402823466e38) ||
				!(next_imag == next_imag && next_imag <= 3.402823466e38 && next_imag >= -3.402823466e38) do return -1
			real = next_real
			imag = next_imag
		}
		computed[2*point] = real
		computed[2*point+1] = imag
	}
	for component := 0; component < 2*count; component += 1 {
		put_f32(output, component*4, computed[component])
	}
	return i64(needed)
}
