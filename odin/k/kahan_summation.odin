package kahan_summation

import "core:c"

@(export)
kahan_summation :: proc "c" (values: [^]f64, length: c.size_t,
                              output: [^]f64, capacity: c.size_t) -> i64 {
	if values == nil || length > c.size_t(256) do return -1
	for i: c.size_t = 0; i < length; i += 1 {
		value := values[i]
		if value != value || value < -1.0e100 || value > 1.0e100 do return -1
	}
	if output == nil || capacity < c.size_t(1) do return -2

	sum: f64 = 0.0
	correction: f64 = 0.0
	for i: c.size_t = 0; i < length; i += 1 {
		adjusted := values[i] - correction
		next := sum + adjusted
		correction = (next - sum) - adjusted
		sum = next
	}
	output[0] = sum
	return 1
}
