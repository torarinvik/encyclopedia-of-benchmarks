package misc_fp_convert

import "core:c"

MAX_ITERATIONS :: 256
VECTOR_LENGTH :: 2048

@(export, link_name="misc_fp_convert")
misc_fp_convert :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length != 1 do return -1
	requested := input[0]
	if requested != requested || requested < 1.0 || requested > f64(MAX_ITERATIONS) do return -1
	if f64(i64(requested)) != requested do return -1
	if output == nil || output_capacity < 1 do return -2

	iterations := i64(requested)
	x: [VECTOR_LENGTH]f32
	y: [VECTOR_LENGTH]f32
	a := f32(0)
	b := f32(1)
	total := f64(0)
	for iteration := i64(0); iteration < iterations; iteration += 1 {
		if iteration % 10 != 0 {
			a = 0
			b = 1
		} else {
			a += f32(0.1)
			b += f32(0.2)
		}
		for index := 0; index < VECTOR_LENGTH; index += 1 {
			x[index] = a + f32(index)
			y[index] = b + f32(index)
		}
		accumulator := f64(0)
		for index := 0; index < VECTOR_LENGTH; index += 1 {
			accumulator += f64(x[index]) * f64(y[index])
		}
		total += accumulator
	}
	output[0] = total
	return 1
}
