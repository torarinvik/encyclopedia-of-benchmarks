package equilibrium_index_in_array

import "core:c"

@(export)
equilibrium_index_in_array :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 1025 do return -2
	n := values[0]
	if n < 0 || n > 1024 || length != c.size_t(n + 1) do return -2
	total := i64(0)
	for i := c.size_t(1); i < length; i += 1 {
		if values[i] < -2147483648 || values[i] > 2147483647 do return -2
		total += values[i]
	}
	left := i64(0)
	for i := i64(0); i < n; i += 1 {
		value := values[c.size_t(i + 1)]
		total -= value
		if left == total do return i
		left += value
	}
	return -1
}
