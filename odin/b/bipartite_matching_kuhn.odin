package bipartite_matching_kuhn

import "core:c"

MAX_SIDE :: 64
MAX_EDGES :: MAX_SIDE * MAX_SIDE

try_augment :: proc "contextless" (left, right_count: int, adjacency: [^]bool,
		seen_right: [^]bool, pair_right: [^]i32) -> bool {
	for right := 0; right < right_count; right += 1 {
		if !adjacency[left * MAX_SIDE + right] || seen_right[right] do continue
		seen_right[right] = true
		mate := pair_right[right]
		if mate < 0 || try_augment(int(mate), right_count, adjacency, seen_right, pair_right) {
			pair_right[right] = i32(left)
			return true
		}
	}
	return false
}

// Return maximum matching cardinality, or -1 for malformed graph input.
@(export)
bipartite_matching_kuhn :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length < 3 do return -1
	if input[0] < 0 || input[0] > MAX_SIDE || input[1] < 0 || input[1] > MAX_SIDE ||
		input[2] < 0 || input[2] > MAX_EDGES do return -1
	left_count := int(input[0])
	right_count := int(input[1])
	edge_count := int(input[2])
	if int(length) != 3 + 2 * edge_count do return -1
	adjacency: [MAX_SIDE * MAX_SIDE]bool
	for edge := 0; edge < edge_count; edge += 1 {
		left := input[3 + 2 * edge]
		right := input[4 + 2 * edge]
		if left < 0 || left >= i64(left_count) || right < 0 || right >= i64(right_count) do return -1
		adjacency[int(left) * MAX_SIDE + int(right)] = true
	}
	pair_right: [MAX_SIDE]i32
	for right := 0; right < right_count; right += 1 do pair_right[right] = -1
	matching := i64(0)
	for left := 0; left < left_count; left += 1 {
		seen_right: [MAX_SIDE]bool
		if try_augment(left, right_count, &adjacency[0], &seen_right[0], &pair_right[0]) do matching += 1
	}
	return matching
}
