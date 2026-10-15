package maximum_sum_of_distinct_subarrays_with_length_k

import "core:c"

@(export)
maximum_sum_of_distinct_subarrays_with_length_k :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	invalid := i64(-9223372036854775807) - 1
	if values == nil || length < 3 || length > 8194 do return invalid
	n_value, k_value := values[0], values[1]
	if n_value < 1 || n_value > 8192 || k_value < 1 || k_value > n_value do return invalid
	n, k := int(n_value), int(k_value)
	if length != c.size_t(n + 2) do return invalid
	keys: [16384]i32
	last_plus_one: [16384]i32
	current_sum: i64 = 0
	maximum_sum: i64 = 0
	distinct_start := 0
	for i := 0; i < n; i += 1 {
		input := values[i + 2]
		if input < -2147483648 || input > 2147483647 do return invalid
		value := i32(input)
		if i < k do current_sum += value
		else {
			current_sum -= values[i - k + 2]
			current_sum += value
		}
		slot := int((input + 2147483648) % 16384)
		for last_plus_one[slot] != 0 && keys[slot] != value do slot = (slot + 1) & 16383
		if last_plus_one[slot] != 0 {
			previous := int(last_plus_one[slot] - 1)
			if previous >= distinct_start do distinct_start = previous + 1
		} else keys[slot] = value
		last_plus_one[slot] = i32(i + 1)
		if i + 1 >= k {
			start := i + 1 - k
			if start >= distinct_start && current_sum > maximum_sum do maximum_sum = current_sum
		}
	}
	return maximum_sum
}
