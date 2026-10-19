package sieve

import "core:c"

SIEVE_LIMIT :: 8192
MAX_ITERATIONS :: 64

@(export, link_name="sieve")
sieve :: proc "c" (iterations: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if iterations < 0 || iterations > MAX_ITERATIONS do return -1

	flags: [SIEVE_LIMIT + 1]u8
	count: i64 = 0
	for pass := i64(0); pass < iterations; pass += 1 {
		count = 0
		for value := 2; value <= SIEVE_LIMIT; value += 1 do flags[value] = 1
		for value := 2; value <= SIEVE_LIMIT; value += 1 {
			if flags[value] != 0 {
				count += 1
				for multiple := value + value; multiple <= SIEVE_LIMIT; multiple += value {
					flags[multiple] = 0
				}
			}
		}
	}

	reversed_digits: [10]u8
	digit_count := 0
	remaining := count
	for {
		reversed_digits[digit_count] = u8(48 + remaining % 10)
		digit_count += 1
		remaining /= 10
		if remaining == 0 do break
	}
	required := 8 + digit_count
	if output == nil || output_capacity < c.size_t(required) do return -2
	output[0] = 67; output[1] = 111; output[2] = 117
	output[3] = 110; output[4] = 116; output[5] = 58
	output[6] = 32
	for index := 0; index < digit_count; index += 1 {
		output[7 + index] = reversed_digits[digit_count - index - 1]
	}
	output[required - 1] = 10
	return i64(required)
}
