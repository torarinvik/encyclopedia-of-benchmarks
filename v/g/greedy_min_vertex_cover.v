module greedy_min_vertex_cover

const max_vertices = 16

fn bit_count(value u64) int {
	mut remaining := value
	mut count := 0
	for remaining != 0 { remaining &= remaining - 1; count++ }
	return count
}

@[export: 'greedy_min_vertex_cover']
pub fn greedy_min_vertex_cover(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > max_vertices + 1 { return -1 }
	unsafe {
		count_value := values[0]
		if count_value < 1 || count_value > max_vertices || length != usize(count_value + 1) { return -1 }
		count := int(count_value)
		limit := (u64(1) << count) - 1
		mut neighbors := [16]u64{}
		for vertex in 0 .. count {
			mask_value := values[vertex + 1]
			if mask_value < 0 || u64(mask_value) > limit { return -1 }
			mask := u64(mask_value)
			if (mask & (u64(1) << vertex)) != 0 { return -1 }
			neighbors[vertex] = mask
		}
		for vertex in 0 .. count {
			for other in vertex + 1 .. count {
				if ((neighbors[vertex] >> other) & 1) != ((neighbors[other] >> vertex) & 1) { return -1 }
			}
		}
		mut chosen := u64(0)
		for {
			mut best_vertex := -1
			mut best_degree := 0
			for vertex in 0 .. count {
				degree := bit_count(neighbors[vertex])
				if degree > best_degree { best_vertex = vertex; best_degree = degree }
			}
			if best_vertex < 0 { return i64(chosen) }
			bit := u64(1) << best_vertex
			chosen |= bit
			for vertex in 0 .. count { neighbors[vertex] &= ~bit }
			neighbors[best_vertex] = 0
		}
	}
}
