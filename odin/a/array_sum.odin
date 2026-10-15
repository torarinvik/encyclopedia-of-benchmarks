package array_sum

import "core:c"

@(export)
array_sum :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 do return -1
	count_value := values[0]
	if count_value < 0 || count_value > 1024 do return -1
	count := c.size_t(count_value)
	if length != count + 1 do return -1
	sum := i64(0)
	for i in 0..<count {
		value := values[i + 1]
		if value < 0 || value > 1000000000 do return -1
		sum += value
	}
	return sum
}
