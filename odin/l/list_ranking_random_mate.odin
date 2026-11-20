package list_ranking_random_mate

import "core:c"

MAX_N :: 8
MAX_ROUNDS :: 32
MAX_INPUT :: 275
MAX_OUTPUT :: 64

put64 :: proc(output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[position + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
list_ranking_random_mate :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT do return -1
	n64, head64 := input[0], input[1]
	if n64 < 1 || n64 > MAX_N || head64 < 0 || head64 >= n64 do return -1
	n, head := int(n64), int(head64)
	if length < c.size_t(3 + 2*n) do return -1
	rounds64 := input[2 + 2*n]
	if rounds64 < 0 || rounds64 > MAX_ROUNDS || length != c.size_t(3 + 2*n64 + rounds64*n64) do return -1
	rounds := int(rounds64)
	weight: [MAX_N]i64
	successor: [MAX_N]i64
	indegree: [MAX_N]int
	tails := 0
	for index := 0; index < n; index += 1 {
		weight[index] = input[2 + index]
		successor[index] = input[2 + n + index]
		if weight[index] < 1 || weight[index] > 10000 || successor[index] < -1 || successor[index] >= n64 do return -1
		if successor[index] == -1 { tails += 1 } else {
			target := int(successor[index])
			indegree[target] += 1
			if indegree[target] > 1 do return -1
		}
	}
	if tails != 1 || indegree[head] != 0 do return -1
	coin_start := 3 + 2*n
	for index := 0; index < rounds*n; index += 1 {
		coin := input[coin_start + index]
		if coin < 0 || coin > 1 do return -1
	}

	seen: [MAX_N]bool
	path_length := 0
	node := head64
	for node != -1 {
		index := int(node)
		if seen[index] || path_length == n do return -1
		seen[index] = true
		path_length += 1
		node = successor[index]
	}
	if path_length != n do return -1

	active: [MAX_N]bool
	removal_round: [MAX_N]int
	for index := 0; index < n; index += 1 { active[index] = true; removal_round[index] = -1 }
	for round := 0; round < rounds && successor[head] != -1; round += 1 {
		old_successor := successor
		old_weight := weight
		remove: [MAX_N]bool
		coin_offset := coin_start + round*n
		for index := 0; index < n; index += 1 {
			target_value := old_successor[index]
			if active[index] && target_value != -1 && input[coin_offset + index] == 0 &&
				input[coin_offset + int(target_value)] == 1 {
				target := int(target_value)
				remove[target] = true
				removal_round[target] = round
			}
		}
		for index := 0; index < n; index += 1 {
			target_value := old_successor[index]
			if active[index] && target_value != -1 && remove[int(target_value)] {
				target := int(target_value)
				weight[index] = old_weight[index] + old_weight[target]
				successor[index] = old_successor[target]
			}
		}
		for index := 0; index < n; index += 1 { if remove[index] { active[index] = false } }
	}
	if successor[head] != -1 do return -1

	rank := weight
	for remaining := rounds; remaining > 0; remaining -= 1 {
		round := remaining - 1
		for index := 0; index < n; index += 1 {
			if removal_round[index] == round && successor[index] != -1 { rank[index] += rank[int(successor[index])] }
		}
	}
	output_bytes := 8*n
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT]u8
	for index := 0; index < n; index += 1 { put64(&staged[0], 8*index, rank[index]) }
	for index := 0; index < output_bytes; index += 1 { output[index] = staged[index] }
	return i64(output_bytes)
}
