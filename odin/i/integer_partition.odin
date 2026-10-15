package integer_partition

import "core:c"

@(export)
integer_partition :: proc "c" (m: i64) -> i64 {
	if m < 1 || m > 300 do return -9223372036854775807 - 1
	 memo: [90300]i64
	for i: i64 = 0; i <= m; i += 1 { memo[i * 300] = 1 }
	for n: i64 = 0; n <= m; n += 1 {
		for k: i64 = 1; k < m; k += 1 {
			index := n * 300 + k
			memo[index] += memo[index - 1]
			if n - k > 0 { memo[index] += memo[(n-k-1)*300+k] }
		}
	}
	return memo[m*300+m-1]
}
