package minimum_directed_feedback_arc_set

import "core:c"

MAX_N :: 8
MAX_M :: 56
MAX_LENGTH :: 114
MAX_STATES :: 256
INF :: i64(2305843009213693951)

@(export)
minimum_directed_feedback_arc_set :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_LENGTH + 1) do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M do return -1
	n := int(input[0])
	m := int(input[1])
	if length != c.size_t(2 + 2*m) do return -1

	var outgoing: [MAX_N]int
	for edge := 0; edge < m; edge += 1 {
		tail_value := input[2 + 2*edge]
		head_value := input[3 + 2*edge]
		if tail_value < 0 || head_value < 0 || tail_value >= i64(n) || head_value >= i64(n) || tail_value == head_value do return -1
		tail := int(tail_value)
		head := int(head_value)
		bit := 1 << head
		if (outgoing[tail] & bit) != 0 do return -1
		outgoing[tail] |= bit
	}

	full := (1 << n)-1
	var dp: [MAX_STATES]i64
	for mask := 0; mask < MAX_STATES; mask += 1 do dp[mask] = INF
	dp[0] = 0
	for prefix := 0; prefix <= full; prefix += 1 {
		if dp[prefix] == INF do continue
		for vertex := 0; vertex < n; vertex += 1 {
			bit := 1 << vertex
			if (prefix & bit) != 0 do continue
			backward: i64 = 0
			for prior := 0; prior < n; prior += 1 {
				if (prefix & (1 << prior)) != 0 && (outgoing[vertex] & (1 << prior)) != 0 {
					backward += 1
				}
			}
			target := prefix | bit
			candidate := dp[prefix] + backward
			if candidate < dp[target] do dp[target] = candidate
		}
	}
	return dp[full]
}
