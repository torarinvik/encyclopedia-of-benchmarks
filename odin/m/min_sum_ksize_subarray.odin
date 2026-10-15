package min_sum_ksize_subarray

import "core:c"

@(export)
min_sum_ksize_subarray :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	invalid := i64(-9223372036854775807) - 1
	if values == nil || length < 2 || length > 100002 do return invalid
	n_value, k_value := values[0], values[1]
	if n_value < 0 || n_value > 100000 || k_value < 0 || k_value > 100000 do return invalid
	n, k := int(n_value), int(k_value)
	if length != c.size_t(n + 2) do return invalid
	for i := 0; i < n; i += 1 {
		if values[i + 2] < -10000 || values[i + 2] > 10000 do return invalid
	}
	if k > n do return -1
	window_sum: i64 = 0
	for i := 0; i < k; i += 1 do window_sum += values[i + 2]
	minimum_sum := window_sum
	for i := k; i < n; i += 1 {
		window_sum += values[i + 2] - values[i - k + 2]
		if window_sum < minimum_sum do minimum_sum = window_sum
	}
	return minimum_sum
}
