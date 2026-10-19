package matmul_f64_4x4

import "core:c"

MAX_ITERATIONS :: 10_000
MATRIX_ELEMENTS :: 16
A: [16]f64 = [16]f64{4.5, 1.3, 6.0, 4.1, 2.5, 7.2, 7.7, 1.7, 6.7, 1.3, 9.4, 1.3, 1.1, 2.2, 3.0, 2.1}
B: [16]f64 = [16]f64{1.0, 7.9, 5.1, 3.4, 6.6, 2.8, 5.4, 9.2, 5.0, 4.1, 4.1, 9.9, 8.4, 3.7, 9.5, 6.4}

@(export, link_name="matmul_f64_4x4")
matmul_f64_4x4 :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length != c.size_t(1) do return -1
	requested := input[0]
	if requested != requested || requested < 1.0 || requested > f64(MAX_ITERATIONS) do return -1
	if f64(i64(requested)) != requested do return -1
	iterations := i64(requested)

	staged: [MATRIX_ELEMENTS]f64
	for _iteration := i64(0); _iteration < iterations; _iteration += 1 {
		for row := 0; row < 4; row += 1 {
			for column := 0; column < 4; column += 1 {
				sum := A[row * 4] * B[column]
				sum += A[row * 4 + 1] * B[4 + column]
				sum += A[row * 4 + 2] * B[8 + column]
				sum += A[row * 4 + 3] * B[12 + column]
				staged[row * 4 + column] = sum
			}
		}
	}
	if output == nil || output_capacity < c.size_t(MATRIX_ELEMENTS) do return -2
	for index := 0; index < MATRIX_ELEMENTS; index += 1 do output[index] = staged[index]
	return i64(MATRIX_ELEMENTS)
}
