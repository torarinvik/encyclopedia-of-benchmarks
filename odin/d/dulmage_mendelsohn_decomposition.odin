package dulmage_mendelsohn_decomposition

import "core:c"

SIDE :: 6
VERTICES :: 12
MAX_EDGES :: 36
MAX_PARSEABLE_LENGTH :: 76

dm_augment :: proc "contextless" (left, right_count: int, adjacency: [SIDE]u16,
		seen: ^[SIDE]bool, match_right: ^[SIDE]int) -> bool {
	for right := 0; right < right_count; right += 1 {
		bit := u16(1) << u16(right)
		if adjacency[left] & bit == 0 || seen[right] do continue
		seen[right] = true
		mate := match_right[right]
		if mate < 0 || dm_augment(mate, right_count, adjacency, seen, match_right) {
			match_right[right] = left
			return true
		}
	}
	return false
}

dm_matching :: proc "contextless" (left_count, right_count: int, adjacency: [SIDE]u16,
		match_left: ^[SIDE]int, match_right: ^[SIDE]int) -> int {
	for right := 0; right < SIDE; right += 1 { match_right[right] = -1 }
	size := 0
	for left := 0; left < left_count; left += 1 {
		seen: [SIDE]bool
		if dm_augment(left, right_count, adjacency, &seen, match_right) do size += 1
	}
	for left := 0; left < SIDE; left += 1 { match_left[left] = -1 }
	for right := 0; right < right_count; right += 1 {
		if match_right[right] >= 0 do match_left[match_right[right]] = right
	}
	return size
}

@(export)
dulmage_mendelsohn_decomposition :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	left_value, right_value, edge_value := input[0], input[1], input[2]
	if left_value < 0 || left_value > SIDE || right_value < 0 || right_value > SIDE ||
		left_value + right_value < 1 || edge_value < 0 || edge_value > MAX_EDGES ||
		edge_value > left_value*right_value do return -1
	left_count, right_count, edge_count := int(left_value), int(right_value), int(edge_value)
	total := left_count + right_count
	if int(length) != 3 + 2*edge_count do return -1
	adjacency: [SIDE]u16
	global: [VERTICES]u16
	for edge := 0; edge < edge_count; edge += 1 {
		u64, v64 := input[3+2*edge], input[4+2*edge]
		if u64 < 0 || u64 >= left_value || v64 < 0 || v64 >= right_value do return -1
		u, v := int(u64), int(v64)
		right_vertex := left_count + v
		bit := u16(1) << u16(v)
		if adjacency[u] & bit != 0 do return -1
		adjacency[u] |= bit
		global[u] |= u16(1) << u16(right_vertex)
		global[right_vertex] |= u16(1) << u16(u)
	}
	match_left: [SIDE]int
	match_right: [SIDE]int
	matching_size := dm_matching(left_count, right_count, adjacency, &match_left, &match_right)
	seen: [2*VERTICES]bool
	queue: [2*VERTICES]int
	head, tail := 0, 0
	for left := 0; left < left_count; left += 1 {
		if match_left[left] < 0 { state := 2*left; seen[state] = true; queue[tail] = state; tail += 1 }
	}
	for right := 0; right < right_count; right += 1 {
		if match_right[right] < 0 { state := 2*(left_count+right); seen[state] = true; queue[tail] = state; tail += 1 }
	}
	for head < tail {
		state := queue[head]
		head += 1
		vertex, parity := state/2, state%2
		for neighbor := 0; neighbor < total; neighbor += 1 {
			if global[vertex] & (u16(1) << u16(neighbor)) == 0 do continue
			matched := false
			if vertex < left_count { matched = match_left[vertex] == neighbor-left_count }
			else { matched = match_right[vertex-left_count] == neighbor }
			if (parity == 0 && matched) || (parity == 1 && !matched) do continue
			next_state := 2*neighbor + 1 - parity
			if !seen[next_state] { seen[next_state] = true; queue[tail] = next_state; tail += 1 }
		}
	}
	packed := u64(matching_size) << 32
	for vertex := 0; vertex < total; vertex += 1 {
		code := 2
		if seen[2*vertex] { code = 0 } else if seen[2*vertex+1] { code = 1 }
		packed |= u64(code) << u64(2*vertex)
	}
	return i64(packed)
}
