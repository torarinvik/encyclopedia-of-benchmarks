package shortest_common_supersequence_length

import "core:c"

// Return shortest common supersequence length for two packed ASCII sequences.
@(export)
shortest_common_supersequence_length :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > 512 do return -1
	m := packed[0]
	n := packed[1]
	if m < 0 || m > 255 || n < 0 || n > 255 do return -1
	if length != c.size_t(2 + m + n) do return -1
	for k := c.size_t(0); k < c.size_t(m + n); k += 1 {
		if packed[2 + k] < 0 || packed[2 + k] > 127 do return -1
	}

	columns := int(n + 1)
	dp: [65536]i64
	for i := 1; i <= int(m); i += 1 {
		for j := 1; j <= int(n); j += 1 {
			cell := i * columns + j
			if packed[1 + c.size_t(i)] == packed[1 + c.size_t(m) + c.size_t(j)] {
				dp[cell] = dp[(i - 1) * columns + j - 1] + 1
			} else {
				above := dp[(i - 1) * columns + j]
				left := dp[i * columns + j - 1]
				dp[cell] = max(above, left)
			}
		}
	}
	return m + n - dp[int(m) * columns + int(n)]
}
