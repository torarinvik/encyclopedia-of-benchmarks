package prime_factorial

import "core:c"

MAX_INPUT :: i64(4096)
MAX_DISTINCT_FACTORS :: 5

is_prime_by_source_trial_division :: proc "contextless" (candidate: i64) -> bool {
	if candidate == 2 do return true
	half_candidate := candidate / 2 + 1
	for divisor := i64(2); divisor <= half_candidate; divisor += 1 {
		if candidate % divisor == 0 do return false
		if divisor == half_candidate do return true
	}
	return false
}

@(export)
prime_factorial :: proc "c" (value: i64, output: [^]u8,
	output_capacity: c.size_t) -> i64 {
	if value < 2 || value > MAX_INPUT do return -1
	factors: [MAX_DISTINCT_FACTORS]u32
	count := c.size_t(0)
	for candidate := i64(2); candidate <= value; candidate += 1 {
		if is_prime_by_source_trial_division(candidate) && value % candidate == 0 {
			factors[count] = u32(candidate)
			count += 1
		}
	}
	required := count * 4
	if output == nil || output_capacity < required do return -2
	position := c.size_t(0)
	for index := c.size_t(0); index < count; index += 1 {
		factor := factors[index]
		for byte_index := 0; byte_index < 4; byte_index += 1 {
			output[position] = u8(factor & 0xFF)
			factor >>= 8
			position += 1
		}
	}
	return i64(position)
}
