package max_pooling

import "core:c"

MAX_N :: 16
MAX_INPUT_WORDS :: 3 + MAX_N * MAX_N
MAX_PARSEABLE_INPUT_WORDS :: MAX_INPUT_WORDS + 1
MAX_OUTPUT_BYTES :: 8 * MAX_N * MAX_N

put_f64_le :: proc(output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

@(export)
max_pooling :: proc "c" (input: [^]i32, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_PARSEABLE_INPUT_WORDS) do return -1
	n, size, stride := input[0], input[1], input[2]
	if n < 1 || n > MAX_N || size < 1 || size > n || stride < 1 || stride > MAX_N do return -1
	if int(length) != 3 + int(n*n) do return -1
	for i := 0; i < int(n*n); i += 1 {
		if input[3+i] < -1_000_000 || input[3+i] > 1_000_000 do return -1
	}
	out_side := int((n-size)/stride + 1)
	output_count := out_side * out_side
	bytes := output_count * 8
	if output == nil || capacity < c.size_t(bytes) do return -2
	buffer: [MAX_OUTPUT_BYTES]u8
	position := 0
	for row := 0; row < out_side; row += 1 {
		for col := 0; col < out_side; col += 1 {
			start_row, start_col := row*int(stride), col*int(stride)
			maximum := input[3+start_row*int(n)+start_col]
			for r := 0; r < int(size); r += 1 {
				for c := 0; c < int(size); c += 1 {
					value := input[3+(start_row+r)*int(n)+start_col+c]
					if value > maximum do maximum = value
				}
			}
			put_f64_le(&buffer[0], position, f64(maximum))
			position += 8
		}
	}
	for i := 0; i < bytes; i += 1 { output[i] = buffer[i] }
	return i64(bytes)
}
