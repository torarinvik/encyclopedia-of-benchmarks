package single_point_crossover

import "core:c"
import "core:math"

MAX_PARENT_LENGTH :: 31
MAX_INPUT_LENGTH :: 2 + 2 * MAX_PARENT_LENGTH

single_point_crossover :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 6 || input_length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_value, cut_value := input[0], input[1]
	if math.is_nan_f64(n_value) || math.is_inf_f64(n_value) || math.is_nan_f64(cut_value) || math.is_inf_f64(cut_value) do return -1
	if n_value < 2.0 || n_value > f64(MAX_PARENT_LENGTH) || f64(int(n_value)) != n_value ||
	   cut_value < 1.0 || cut_value > n_value - 1.0 || f64(int(cut_value)) != cut_value do return -1
	n, cut := int(n_value), int(cut_value)
	if input_length != c.size_t(2 + 2 * n) do return -1
	first, second: [MAX_PARENT_LENGTH]f64
	for index := 0; index < n; index += 1 {
		first[index], second[index] = input[2 + index], input[2 + n + index]
		if math.is_nan_f64(first[index]) || math.is_inf_f64(first[index]) || math.is_nan_f64(second[index]) || math.is_inf_f64(second[index]) do return -1
	}
	required := 2 * n
	if output == nil || output_capacity < c.size_t(required) do return -2
	for index := 0; index < n; index += 1 {
		if index < cut { output[index] = first[index]; output[n + index] = second[index] }
		else { output[index] = second[index]; output[n + index] = first[index] }
	}
	return i64(required)
}
