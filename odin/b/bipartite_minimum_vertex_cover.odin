package bipartite_minimum_vertex_cover

import "core:c"

MAX_SIDE :: 8
MAX_VERTICES :: 16
MAX_PARSEABLE_INPUT :: 11

augment_left :: proc "contextless" (left, left_count, right_count: int, rows: [^]u16,
	states: [^]int, match_right: [^]int, seen: [^]bool) -> bool {
	for right := 0; right < right_count; right += 1 {
		if (rows[left] & (u16(1) << u16(right))) == 0 || seen[right] || states[left_count+right] != -1 do continue
		seen[right] = true
		owner := match_right[right]
		if owner < 0 || augment_left(owner, left_count, right_count, rows, states, match_right, seen) {
			match_right[right] = left
			return true
		}
	}
	return false
}

maximum_matching :: proc "contextless" (left_count, right_count: int, rows: [^]u16,
	states: [^]int, match_right: [^]int) -> int {
	for right := 0; right < right_count; right += 1 { match_right[right] = -1 }
	size := 0
	for left := 0; left < left_count; left += 1 {
		if states[left] != -1 do continue
		seen: [MAX_SIDE]bool = {}
		if augment_left(left, left_count, right_count, rows, states, match_right, &seen[0]) { size += 1 }
	}
	return size
}

bit_count :: proc "contextless" (value_input: u32) -> int {
	value := value_input
	count := 0
	for value != 0 { count += int(value & 1); value >>= 1 }
	return count
}

alternating_cover :: proc "contextless" (left_count, right_count: int, rows: [^]u16,
	match_right: [^]int) -> u32 {
	matched_left: [MAX_SIDE]bool = {}
	reached_left: [MAX_SIDE]bool = {}
	reached_right: [MAX_SIDE]bool = {}
	queue: [MAX_SIDE]int
	head, tail := 0, 0
	for right := 0; right < right_count; right += 1 {
		if match_right[right] >= 0 { matched_left[match_right[right]] = true }
	}
	for left := 0; left < left_count; left += 1 {
		if !matched_left[left] { reached_left[left] = true; queue[tail] = left; tail += 1 }
	}
	for head < tail {
		left := queue[head]
		head += 1
		for right := 0; right < right_count; right += 1 {
			if (rows[left] & (u16(1) << u16(right))) == 0 || reached_right[right] || match_right[right] < 0 do continue
			reached_right[right] = true
			owner := match_right[right]
			if !reached_left[owner] { reached_left[owner] = true; queue[tail] = owner; tail += 1 }
		}
	}
	result: u32 = 0
	for left := 0; left < left_count; left += 1 { if !reached_left[left] { result |= u32(1) << u32(left) } }
	for right := 0; right < right_count; right += 1 {
		if reached_right[right] { result |= u32(1) << u32(left_count+right) }
	}
	return result
}

minimum_completion_size :: proc "contextless" (left_count, right_count: int, rows: [^]u16,
	input_states: [^]int) -> int {
	states: [MAX_VERTICES]int
	total := left_count + right_count
	for i := 0; i < total; i += 1 { states[i] = input_states[i] }
	changed := true
	for changed {
		changed = false
		for left := 0; left < left_count; left += 1 {
			for right := 0; right < right_count; right += 1 {
				if (rows[left] & (u16(1) << u16(right))) == 0 do continue
				right_vertex := left_count + right
				if states[left] == 0 && states[right_vertex] == 0 { return -1 }
				if states[left] == 0 && states[right_vertex] == -1 {
					states[right_vertex] = 1
					changed = true
				} else if states[right_vertex] == 0 && states[left] == -1 {
					states[left] = 1
					changed = true
				}
			}
		}
	}
	forced_in := 0
	for i := 0; i < total; i += 1 { if states[i] == 1 { forced_in += 1 } }
	residual_match: [MAX_SIDE]int
	return forced_in + maximum_matching(left_count, right_count, rows, &states[0], &residual_match[0])
}

canonical_cover :: proc "contextless" (left_count, right_count: int, rows: [^]u16, optimum: int) -> u32 {
	states: [MAX_VERTICES]int
	total := left_count + right_count
	for i := 0; i < total; i += 1 { states[i] = -1 }
	for vertex := 0; vertex < total; vertex += 1 {
		states[vertex] = 0
		if minimum_completion_size(left_count, right_count, rows, &states[0]) != optimum { states[vertex] = 1 }
	}
	result: u32 = 0
	for vertex := 0; vertex < total; vertex += 1 {
		if states[vertex] == 1 { result |= u32(1) << u32(vertex) }
	}
	return result
}

@(export)
bipartite_minimum_vertex_cover :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT do return -1
	left_value, right_value := input[0], input[1]
	if left_value < 0 || left_value > MAX_SIDE || right_value < 0 || right_value > MAX_SIDE do return -1
	left_count, right_count := int(left_value), int(right_value)
	if length != c.size_t(left_count+2) do return -1
	right_domain := (u64(1) << u64(right_count))-1
	rows: [MAX_SIDE]u16 = {}
	for left := 0; left < left_count; left += 1 {
		row := input[2+left]
		if row < 0 || (u64(row) & ~right_domain) != 0 do return -1
		rows[left] = u16(row)
	}
	free_states: [MAX_VERTICES]int
	for i := 0; i < left_count+right_count; i += 1 { free_states[i] = -1 }
	match_right: [MAX_SIDE]int
	matching_size := maximum_matching(left_count, right_count, &rows[0], &free_states[0], &match_right[0])
	optimum := bit_count(alternating_cover(left_count, right_count, &rows[0], &match_right[0]))
	if optimum != matching_size do return -1
	return i64(canonical_cover(left_count, right_count, &rows[0], optimum))
}
