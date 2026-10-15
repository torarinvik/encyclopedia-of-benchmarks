package unique_permutation

import "core:c"

MAX_LENGTH :: 6

generate :: proc "contextless" (values: [^]i32, n, depth: int, current: [^]i32,
		used: [^]bool, output: [^]u8, result_count: ^int) {
	if depth == n {
		row := result_count^ * n
		for i := 0; i < n; i += 1 { output[row + i] = u8(current[i]) }
		result_count^ += 1
		return
	}
	for i := 0; i < n; i += 1 {
		if used[i] do continue
		if i > 0 && values[i] == values[i - 1] && !used[i - 1] do continue
		current[depth] = values[i]
		used[i] = true
		generate(values, n, depth + 1, current, used, output, result_count)
		used[i] = false
	}
}

@(export)
unique_permutation :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_LENGTH + 1 do return -1
	n_value := input[0]
	if n_value < 0 || n_value > MAX_LENGTH || length != c.size_t(n_value + 1) do return -1
	n := int(n_value)
	values: [MAX_LENGTH]i32
	for i := 0; i < n; i += 1 {
		value := input[i + 1]
		if value < 0 || value > 127 do return -1
		values[i] = i32(value)
	}
	for i := 1; i < n; i += 1 {
		value := values[i]
		position := i
		for position > 0 && values[position - 1] > value { values[position] = values[position - 1]; position -= 1 }
		values[position] = value
	}
	max_count := 1
	for factor := 2; factor <= n; factor += 1 { max_count *= factor }
	required := c.size_t(max_count * n)
	if output_capacity < required || (required > 0 && output == nil) do return -2
	current: [MAX_LENGTH]i32
	used: [MAX_LENGTH]bool
	result_count := 0
	generate(&values[0], n, 0, &current[0], &used[0], output, &result_count)
	return i64(result_count)
}
