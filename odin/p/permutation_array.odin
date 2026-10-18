package permutation_array

import "core:c"

MAX_LENGTH :: 6
MAX_PARSEABLE_LENGTH :: 8

store_i32_le :: proc "contextless" (output: [^]u8, position: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[position + byte] = u8((bits >> u32(byte * 8)) & 255)
	}
}

generate :: proc "contextless" (values: [^]i32, n, index: int, output: [^]u8, result_count: ^int) {
	if index == n {
		row_start := result_count^ * n * 4
		for column := 0; column < n; column += 1 {
			store_i32_le(output, row_start + column * 4, values[column])
		}
		result_count^ += 1
		return
	}
	for position := index; position < n; position += 1 {
		saved := values[index]
		values[index] = values[position]
		values[position] = saved
		generate(values, n, index + 1, output, result_count)
		restore := values[index]
		values[index] = values[position]
		values[position] = restore
	}
}

@(export)
permutation_array :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_LENGTH do return -1
	n_value := input[0]
	if n_value < 0 || n_value > MAX_LENGTH || length != c.size_t(n_value + 1) do return -1
	n := int(n_value)
	values: [MAX_LENGTH]i32
	for index := 0; index < n; index += 1 {
		value := input[index + 1]
		if value < -2147483648 || value > 2147483647 do return -1
		values[index] = i32(value)
	}
	permutation_count := 1
	for factor := 2; factor <= n; factor += 1 { permutation_count *= factor }
	required := c.size_t(permutation_count * n * 4)
	if output_capacity < required || (required > 0 && output == nil) do return -2
	result_count := 0
	generate(&values[0], n, 0, output, &result_count)
	return i64(result_count)
}
