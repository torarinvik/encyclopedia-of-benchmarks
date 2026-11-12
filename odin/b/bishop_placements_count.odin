package bishop_placements_count

import "core:c"

MAX_N :: 8
MAX_K :: 16
MAX_DIAGONALS :: 2 * MAX_N

diagonal_size :: proc(index: int) -> int {
	if index & 1 != 0 do return (index / 4) * 2 + 1
	return ((index - 1) / 4) * 2 + 2
}

color_counts :: proc(k, last_diagonal: int) -> [MAX_K + 1]i64 {
	dp: [MAX_DIAGONALS * (MAX_K + 1)]i64
	dp[0] = 1
	dp[MAX_K + 1] = 1
	if k >= 1 do dp[MAX_K + 2] = 1
	for diagonal := 2; diagonal <= last_diagonal; diagonal += 1 {
		dp[diagonal * (MAX_K + 1)] = 1
		squares := diagonal_size(diagonal)
		for placed := 1; placed <= k; placed += 1 {
			offset := diagonal * (MAX_K + 1) + placed
			previous := (diagonal - 2) * (MAX_K + 1)
			dp[offset] = dp[previous + placed] + dp[previous + placed - 1] * i64(squares - placed + 1)
		}
	}
	counts: [MAX_K + 1]i64
	for placed := 0; placed <= k; placed += 1 {
		counts[placed] = dp[last_diagonal * (MAX_K + 1) + placed]
	}
	return counts
}

@(export)
bishop_placements_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_K do return -1
	n, k := int(input[0]), int(input[1])
	maximum := 2 * n - 2
	if n == 1 do maximum = 1
	if k > maximum do return 0
	black, white: [MAX_K + 1]i64
	black = color_counts(k, 2 * n - 1)
	white = color_counts(k, 2 * n - 2)
	result := i64(0)
	for left := 0; left <= k; left += 1 { result += black[left] * white[k - left] }
	return result
}
