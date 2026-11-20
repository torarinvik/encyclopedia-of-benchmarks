package riordan_number

import "core:c"

MAX_PARSEABLE_LENGTH :: 2
MAX_N :: i64(30)

riordan_number_value :: proc(n: int) -> i64 {
	values: [31]i64
	values[0] = 1
	for size := 2; size <= n; size += 1 {
		values[size] = i64(size-1) * (2*values[size-1] + 3*values[size-2]) / i64(size+1)
	}
	return values[n]
}

@(export)
riordan_number :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	if length != 1 || input[0] < 0 || input[0] > MAX_N do return -1
	return riordan_number_value(int(input[0]))
}
