package golomb_sequence_validator

import "core:c"

MAX_N :: 1024

@(export)
golomb_sequence_validator :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length < 1 || length > MAX_N do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(n) do return -1
	for index := 1; index < n; index += 1 {
		if input[index] < -2147483648 || input[index] > 2147483647 do return -1
	}

	dp: [MAX_N]i64 = {}
	dp[0] = 1
	for i := 1; i < n; i += 1 {
		previous := int(dp[i - 1])
		nested := int(dp[previous])
		source := i - nested
		dp[i] = 1 + dp[source]
	}
	for index := 1; index < n; index += 1 {
		if input[index] != dp[index] do return 0
	}
	return 1
}
