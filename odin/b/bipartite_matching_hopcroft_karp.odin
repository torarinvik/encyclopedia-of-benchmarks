package bipartite_matching_hopcroft_karp

import "core:c"

MAX_SIDE :: 64
MAX_EDGES :: MAX_SIDE * MAX_SIDE
INF_DISTANCE :: 1_000_000

dfs_augment :: proc "contextless" (left, right_count: int, adjacency: [^]bool,
		distance: [^]i32, nil_distance: i32, pair_left, pair_right: [^]i32) -> bool {
	for right := 0; right < right_count; right += 1 {
		if !adjacency[left * MAX_SIDE + right] do continue
		mate := pair_right[right]
		if mate < 0 {
			if distance[left] + 1 != nil_distance do continue
			pair_left[left] = i32(right)
			pair_right[right] = i32(left)
			return true
		}
		if distance[int(mate)] == distance[left] + 1 &&
			dfs_augment(int(mate), right_count, adjacency, distance, nil_distance, pair_left, pair_right) {
			pair_left[left] = i32(right)
			pair_right[right] = i32(left)
			return true
		}
	}
	distance[left] = INF_DISTANCE
	return false
}

bfs_layers :: proc "contextless" (left_count, right_count: int, adjacency: [^]bool,
		pair_right: [^]i32, distance: [^]i32) -> i32 {
	queue: [64]int
	head, tail := 0, 0
	for left := 0; left < left_count; left += 1 {
		if distance[left] == 0 {
			queue[tail] = left
			tail += 1
		}
	}
	nil_distance := i32(INF_DISTANCE)
	for head < tail {
		left := queue[head]
		head += 1
		if distance[left] + 1 > nil_distance do continue
		for right := 0; right < right_count; right += 1 {
			if !adjacency[left * MAX_SIDE + right] do continue
			mate := pair_right[right]
			if mate < 0 {
				nil_distance = min(nil_distance, distance[left] + 1)
			} else if distance[int(mate)] < 0 {
				distance[int(mate)] = distance[left] + 1
				queue[tail] = int(mate)
				tail += 1
			}
		}
	}
	return nil_distance
}

// Return maximum matching cardinality, or -1 for malformed graph input.
@(export)
bipartite_matching_hopcroft_karp :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
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
	pair_left: [MAX_SIDE]i32
	pair_right: [MAX_SIDE]i32
	distance: [MAX_SIDE]i32
	for left := 0; left < left_count; left += 1 do pair_left[left] = -1
	for right := 0; right < right_count; right += 1 do pair_right[right] = -1
	matching := i64(0)
	for {
		for left := 0; left < left_count; left += 1 {
			distance[left] = if pair_left[left] < 0 { 0 } else { -1 }
		}
		nil_distance := bfs_layers(left_count, right_count, &adjacency[0], &pair_right[0], &distance[0])
		if nil_distance == INF_DISTANCE do break
		for left := 0; left < left_count; left += 1 {
			if pair_left[left] < 0 && dfs_augment(left, right_count, &adjacency[0], &distance[0],
				nil_distance, &pair_left[0], &pair_right[0]) do matching += 1
		}
	}
	return matching
}
