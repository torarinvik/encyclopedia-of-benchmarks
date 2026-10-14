module bellman_ford

// Directed edge triples, separate reachability, and checked distance addition.
@[export: 'bellman_ford']
pub fn bellman_ford(edges &i64, vertices usize, edge_count usize, source usize,
				   mut distances &i64, mut reachable &u8) i64 {
	if vertices == 0 {
		return if source == 0 && edge_count == 0 { i64(0) } else { i64(-3) }
	}
	if source >= vertices { return -3 }
	mut edge := usize(0)
	for edge < edge_count {
		origin := unsafe { edges[3 * edge] }
		destination := unsafe { edges[3 * edge + 1] }
		if origin < 0 || destination < 0 || u64(origin) >= u64(vertices) || u64(destination) >= u64(vertices) { return -3 }
		edge++
	}
	mut vertex := usize(0)
	for vertex < vertices {
		unsafe {
			distances[vertex] = 0
			reachable[vertex] = 0
		}
		vertex++
	}
	unsafe { reachable[source] = 1 }
	mut round := usize(0)
	for round < vertices {
		mut changed := false
		edge = 0
		for edge < edge_count {
			origin := usize(unsafe { edges[3 * edge] })
			destination := usize(unsafe { edges[3 * edge + 1] })
			weight := unsafe { edges[3 * edge + 2] }
			if unsafe { reachable[origin] } != 0 {
				base := unsafe { distances[origin] }
				if (weight > 0 && base > i64(9223372036854775807) - weight) ||
				   (weight < 0 && base < (i64(-9223372036854775807) - 1) - weight) { return -2 }
				candidate := base + weight
				if unsafe { reachable[destination] } == 0 || candidate < unsafe { distances[destination] } {
					if round == vertices - 1 { return -1 }
					unsafe {
						distances[destination] = candidate
						reachable[destination] = 1
					}
					changed = true
				}
			}
			edge++
		}
		if !changed { return 0 }
		round++
	}
	return 0
}
