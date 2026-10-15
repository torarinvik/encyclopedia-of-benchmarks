package max_sum_sliding_window

import "core:c"

@(export)
max_sum_sliding_window :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	invalid := i64(-9223372036854775807) - 1
	if values == nil || length < 3 || length > 100002 do return invalid
	n_value, k_value := values[0], values[1]
	if n_value < 1 || n_value > 100000 || k_value < 1 || k_value > n_value do return invalid
	n, k := int(n_value), int(k_value)
	if length != c.size_t(n + 2) do return invalid
	current_sum: i64 = 0
	for i := 0; i < n; i += 1 {
		value := values[i + 2]
		if value < -1000000000 || value > 1000000000 do return invalid
		if i < k do current_sum += value
	}
	maximum_sum := current_sum
	for i := 0; i < n - k; i += 1 {
		current_sum = current_sum - values[i + 2] + values[i + k + 2]
		if current_sum > maximum_sum do maximum_sum = current_sum
	}
	return maximum_sum
}
