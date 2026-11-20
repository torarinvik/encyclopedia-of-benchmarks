package string_compression_ii

import "core:c"

MAX_N :: 12
MAX_INPUT :: 15
WIDTH :: MAX_N + 1
CELLS :: WIDTH * WIDTH
INF :: i64(1000)

run_cost :: proc "contextless" (kept: int) -> i64 {
	if kept == 1 do return 1
	digits := 0
	value := kept
	for value > 0 { digits += 1; value /= 10 }
	return i64(1 + digits)
}

@(export)
string_compression_ii :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n_raw := input[0]
	k_raw := input[1]
	if n_raw < 0 || n_raw > MAX_N || k_raw < 0 || k_raw > n_raw do return -1
	n := int(n_raw)
	budget := int(k_raw)
	if int(length) != n + 2 do return -1
	for i in 0..<n { if input[i + 2] < 0 || input[i + 2] > 25 do return -1 }

	dp: [CELLS]i64
	for i in 0..<CELLS { dp[i] = INF }
	dp[0] = 0
	for start in 0..<n {
		for used in 0..=budget {
			prefix_cost := dp[start * WIDTH + used]
			if prefix_cost == INF do continue
			if used < budget {
				index := (start + 1) * WIDTH + used + 1
				if prefix_cost < dp[index] do dp[index] = prefix_cost
			}
			same := 0
			for end in start..<n {
				if input[end + 2] == input[start + 2] do same += 1
				span := end - start + 1
				for kept in 1..=same {
					total_deleted := used + span - kept
					if total_deleted > budget do continue
					candidate := prefix_cost + run_cost(kept)
					index := (end + 1) * WIDTH + total_deleted
					if candidate < dp[index] do dp[index] = candidate
				}
			}
		}
	}
	answer := INF
	for deleted in 0..=budget {
		value := dp[n * WIDTH + deleted]
		if value < answer do answer = value
	}
	return answer
}
