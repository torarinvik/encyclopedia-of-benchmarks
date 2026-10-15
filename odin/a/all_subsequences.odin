package all_subsequences

import "core:c"

MAX_LENGTH :: 8
BYTES_PER_VALUE :: 4

store_u32_le :: proc "contextless" (output: [^]u8, position: int, value: u32) {
	for byte := 0; byte < 4; byte += 1 {
		output[position + byte] = u8((value >> u32(byte * 8)) & 255)
	}
}

store_i32_le :: proc "contextless" (output: [^]u8, position: int, value: i32) {
	store_u32_le(output, position, u32(value))
}

generate :: proc "contextless" (values: [^]i32, n, index: int, current: [^]i32,
		current_length: int, output: [^]u8, output_cursor, result_count: ^int) {
	if index == n {
		store_u32_le(output, output_cursor^, u32(current_length))
		output_cursor^ += BYTES_PER_VALUE
		for item := 0; item < current_length; item += 1 {
			store_i32_le(output, output_cursor^, current[item])
			output_cursor^ += BYTES_PER_VALUE
		}
		result_count^ += 1
		return
	}
	generate(values, n, index + 1, current, current_length, output, output_cursor, result_count)
	current[current_length] = values[index]
	generate(values, n, index + 1, current, current_length + 1, output, output_cursor, result_count)
}

@(export)
all_subsequences :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_LENGTH + 1 do return -1
	n_value := input[0]
	if n_value < 0 || n_value > MAX_LENGTH || length != c.size_t(n_value + 1) do return -1
	n := int(n_value)
	values: [MAX_LENGTH]i32
	for index := 0; index < n; index += 1 {
		value := input[index + 1]
		if value < -2147483648 || value > 2147483647 do return -1
		values[index] = i32(value)
	}
	result_count := 1
	for index := 0; index < n; index += 1 { result_count *= 2 }
	value_count := 0
	if n > 0 do value_count = n * (result_count / 2)
	required := c.size_t((result_count + value_count) * BYTES_PER_VALUE)
	if output_capacity < required || output == nil do return -2
	current: [MAX_LENGTH]i32
	output_cursor := 0
	emitted := 0
	generate(&values[0], n, 0, &current[0], 0, output, &output_cursor, &emitted)
	return i64(emitted)
}
