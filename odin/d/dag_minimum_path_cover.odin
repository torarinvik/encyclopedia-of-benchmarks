package dag_minimum_path_cover

import "core:c"

MAX_VERTICES :: 10
MAX_EDGES :: 45
MAX_PARSEABLE_LENGTH :: 93

dmpc_augment :: proc "contextless" (left, n: int, used: u16, adjacency: [MAX_VERTICES]u16,
                                     seen: ^[MAX_VERTICES]bool,
                                     match_right: ^[MAX_VERTICES]int) -> bool {
	for right := 0; right < n; right += 1 {
		bit := u16(1) << u16(right)
		if adjacency[left] & bit == 0 || used & bit != 0 || seen[right] do continue
		seen[right] = true
		mate := match_right[right]
		if mate < 0 || dmpc_augment(mate, n, used, adjacency, seen, match_right) {
			match_right[right] = left
			return true
		}
	}
	return false
}

dmpc_maximum :: proc "contextless" (n, first: int, used: u16,
		adjacency: [MAX_VERTICES]u16) -> int {
	match_right: [MAX_VERTICES]int
	for right := 0; right < MAX_VERTICES; right += 1 { match_right[right] = -1 }
	size := 0
	for left := first; left < n; left += 1 {
		seen: [MAX_VERTICES]bool
		if dmpc_augment(left, n, used, adjacency, &seen, &match_right) do size += 1
	}
	return size
}

@(export)
dag_minimum_path_cover :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	n_value, m_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES do return -1
	n, m := int(n_value), int(m_value)
	if int(length) != 2 + 2*m do return -1

	adjacency: [MAX_VERTICES]u16
	indegree: [MAX_VERTICES]int
	for edge := 0; edge < m; edge += 1 {
		u64, v64 := input[2+2*edge], input[3+2*edge]
		if u64 < 0 || u64 >= n_value || v64 < 0 || v64 >= n_value || u64 == v64 do return -1
		u, v := int(u64), int(v64)
		bit := u16(1) << u16(v)
		if adjacency[u] & bit != 0 do return -1
		adjacency[u] |= bit
		indegree[v] += 1
	}
	queue: [MAX_VERTICES]int
	head, tail := 0, 0
	for vertex := 0; vertex < n; vertex += 1 {
		if indegree[vertex] == 0 { queue[tail] = vertex; tail += 1 }
	}
	removed := 0
	for head < tail {
		u := queue[head]
		head += 1
		removed += 1
		for v := 0; v < n; v += 1 {
			if adjacency[u] & (u16(1) << u16(v)) != 0 {
				indegree[v] -= 1
				if indegree[v] == 0 { queue[tail] = v; tail += 1 }
			}
		}
	}
	if removed != n do return -1

	maximum := dmpc_maximum(n, 0, 0, adjacency)
	successor: [MAX_VERTICES]int
	used: u16 = 0
	fixed := 0
	for left := 0; left < n; left += 1 {
		chosen := false
		for right := 0; right <= n; right += 1 {
			matched := right < n
			if matched {
				bit := u16(1) << u16(right)
				if adjacency[left] & bit == 0 || used & bit != 0 do continue
			}
			next_used := used
			if matched do next_used |= u16(1) << u16(right)
			if fixed + int(matched) + dmpc_maximum(n, left+1, next_used, adjacency) == maximum {
				successor[left] = right
				used = next_used
				if matched do fixed += 1
				chosen = true
				break
			}
		}
		if !chosen do return -1
	}
	packed := u64(n-maximum) << 40
	for vertex := 0; vertex < n; vertex += 1 { packed |= u64(successor[vertex]) << u64(4*vertex) }
	return i64(packed)
}
