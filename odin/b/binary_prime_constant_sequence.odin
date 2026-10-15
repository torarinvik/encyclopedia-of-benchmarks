package binary_prime_constant_sequence

import "core:c"

MAX_COUNT :: 4096

is_prime :: proc(candidate: i64) -> bool {
	if candidate < 2 do return false
	for divisor := i64(2); divisor <= candidate / divisor; divisor += 1 {
		if candidate % divisor == 0 do return false
	}
	return true
}

@(export)
binary_prime_constant_sequence :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 1 || input[0] < 0 || input[0] > MAX_COUNT do return -1
	count := c.size_t(input[0])
	if output_capacity < count || (count > 0 && output == nil) do return -2

	next := c.size_t(1)
	for candidate := i64(2); candidate <= input[0]; candidate += 1 {
		if !is_prime(candidate) do continue
		for next < c.size_t(candidate) {
			output[next - 1] = 0
			next += 1
		}
		output[c.size_t(candidate) - 1] = 1
		next = c.size_t(candidate) + 1
	}
	for next <= count {
		output[next - 1] = 0
		next += 1
	}
	return i64(count)
}
