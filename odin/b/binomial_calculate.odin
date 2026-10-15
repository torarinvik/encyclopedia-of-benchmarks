package binomial_calculate

import "core:c"

@(export)
binomial_calculate :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	n, k := input[0], input[1]
	if n < 0 || n > 62 || k < 0 || k > n do return -1
	if k > n / 2 do k = n - k
	result: u64 = 1
	for i: i64 = 1; i <= k; i += 1 {
		result *= u64(n - k + i)
		result /= u64(i)
	}
	return i64(result)
}
