package greedy_min_vertex_cover

import "core:c"

MAX_VERTICES :: 16

bit_count :: proc "contextless" (value: u64) -> int {
	remaining := value
	count := 0
	for remaining != 0 { remaining &= remaining - 1; count += 1 }
	return count
}

@(export)
greedy_min_vertex_cover :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_VERTICES + 1 do return -1
	count_value := values[0]
	if count_value < 1 || count_value > MAX_VERTICES || length != c.size_t(count_value + 1) do return -1
	count := int(count_value)
	limit := (u64(1) << count) - 1
	neighbors: [MAX_VERTICES]u64
	for vertex := 0; vertex < count; vertex += 1 {
		mask_value := values[vertex + 1]
		if mask_value < 0 || u64(mask_value) > limit do return -1
		mask := u64(mask_value)
		if (mask & (u64(1) << vertex)) != 0 do return -1
		neighbors[vertex] = mask
	}
	for vertex := 0; vertex < count; vertex += 1 {
		for other := vertex + 1; other < count; other += 1 {
			if ((neighbors[vertex] >> other) & 1) != ((neighbors[other] >> vertex) & 1) do return -1
		}
	}
	chosen := u64(0)
	for {
		best_vertex, best_degree := -1, 0
		for vertex := 0; vertex < count; vertex += 1 {
			degree := bit_count(neighbors[vertex])
			if degree > best_degree { best_vertex, best_degree = vertex, degree }
		}
		if best_vertex < 0 do return i64(chosen)
		bit := u64(1) << best_vertex
		chosen |= bit
		for vertex := 0; vertex < count; vertex += 1 { neighbors[vertex] &= ~bit }
		neighbors[best_vertex] = 0
	}
}
