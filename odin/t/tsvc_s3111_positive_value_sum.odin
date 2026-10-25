package tsvc_s3111_positive_value_sum

import "core:c"

MAX_N :: 64
MAX_INPUT_LENGTH :: 1 + MAX_N
MAX_VALUE :: i64(1_000_000)

@(export)
tsvc_s3111_positive_value_sum :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_raw := input[0]
	if n_raw < 0 || n_raw > MAX_N do return -1
	n := int(n_raw)
	if int(length) != 1 + n do return -1

	sum := i64(0)
	for i := 0; i < n; i += 1 {
		value := input[i + 1]
		if value < -MAX_VALUE || value > MAX_VALUE do return -1
		if value > 0 do sum += value
	}
	return sum
}
