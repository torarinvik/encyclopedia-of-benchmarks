package motzkin_number

import "core:c"

MAX_PARSEABLE_LENGTH :: 2
MAX_N :: i64(30)

motzkin_number_value :: proc(n: int) -> i64 {
	values: [31]i64
	values[0] = 1
	if n >= 1 do values[1] = 1
	for size := 2; size <= n; size += 1 {
		total := values[size-1]
		for left := 0; left < size-1; left += 1 {
			total += values[left] * values[size-2-left]
		}
		values[size] = total
	}
	return values[n]
}

@(export)
motzkin_number :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	if length != 1 || input[0] < 0 || input[0] > MAX_N do return -1
	return motzkin_number_value(int(input[0]))
}
