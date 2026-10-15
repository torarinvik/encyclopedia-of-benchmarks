package all_permutations

import "core:c"

MAX_LENGTH :: 6
BYTES_PER_VALUE :: 4

store_i32_le :: proc "contextless" (output: [^]u8, position: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[position + byte] = u8((bits >> u32(byte * 8)) & 255)
	}
}

generate :: proc "contextless" (values: [^]i32, n, depth: int, current: [^]i32,
		used: [^]bool, output: [^]u8, result_count: ^int) {
	if depth == n {
		row_start := result_count^ * n * BYTES_PER_VALUE
		for index := 0; index < n; index += 1 {
			store_i32_le(output, row_start + index * BYTES_PER_VALUE, current[index])
		}
		result_count^ += 1
		return
	}
	for index := 0; index < n; index += 1 {
		if used[index] do continue
		current[depth] = values[index]
		used[index] = true
		generate(values, n, depth + 1, current, used, output, result_count)
		used[index] = false
	}
}

@(export)
all_permutations :: proc "c" (input: [^]i64, length: c.size_t,
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
	permutation_count := 1
	for factor := 2; factor <= n; factor += 1 { permutation_count *= factor }
	required := c.size_t(permutation_count * n * BYTES_PER_VALUE)
	if output_capacity < required || (required > 0 && output == nil) do return -2
	current: [MAX_LENGTH]i32
	used: [MAX_LENGTH]bool
	for index := 0; index < n; index += 1 { used[index] = false }
	result_count := 0
	generate(&values[0], n, 0, &current[0], &used[0], output, &result_count)
	return i64(result_count)
}
