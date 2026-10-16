package bron_kerbosch

import "core:c"

population_count :: proc "contextless" (value: u64) -> int {
	bits := value
	count := 0
	for bits != 0 {
		count += int(bits & 1)
		bits >>= 1
	}
	return count
}

search :: proc "contextless" (vertex_count: int, adjacency: [5]u64, clique, possible, excluded: u64) -> u64 {
	if possible == 0 && excluded == 0 do return u64(1) << clique

	pivot := -1
	greatest_degree := -1
	pivot_choices := possible | excluded
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		if pivot_choices & (u64(1) << u64(vertex)) == 0 do continue
		degree := population_count(adjacency[vertex])
		if degree > greatest_degree {
			pivot = vertex
			greatest_degree = degree
		}
	}

	candidates := possible
	if pivot >= 0 do candidates &= ~adjacency[pivot]
	result: u64 = 0
	remaining_possible := possible
	remaining_excluded := excluded
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		bit := u64(1) << u64(vertex)
		if candidates & bit == 0 do continue
		result |= search(vertex_count, adjacency, clique | bit,
			remaining_possible & adjacency[vertex], remaining_excluded & adjacency[vertex])
		remaining_possible &= ~bit
		remaining_excluded |= bit
	}
	return result
}

@(export)
bron_kerbosch :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 7 do return -1
	if input[0] < 0 || input[0] > 5 do return -1
	vertex_count := int(input[0])
	if length != c.size_t(vertex_count + 1) do return -1

	vertex_mask := (u64(1) << u64(vertex_count)) - 1
	adjacency: [5]u64
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		row := input[vertex + 1]
		if row < 0 || u64(row) & ~vertex_mask != 0 do return -1
		adjacency[vertex] = u64(row) & ~(u64(1) << u64(vertex))
	}
	for left := 0; left < vertex_count; left += 1 {
		for right := left + 1; right < vertex_count; right += 1 {
			if (adjacency[left] >> u64(right)) & 1 != (adjacency[right] >> u64(left)) & 1 do return -1
		}
	}
	return i64(search(vertex_count, adjacency, 0, vertex_mask, 0))
}
