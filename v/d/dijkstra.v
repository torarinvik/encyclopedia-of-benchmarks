module dijkstra

// Directed edge triples, nonnegative weights, separate reachability.
@[export: 'dijkstra']
pub fn dijkstra(edges &i64, vertices usize, edge_count usize, source usize,
                mut distances &i64, mut reachable &u8) i64 {
	if vertices == 0 {
		return if source == 0 && edge_count == 0 { i64(0) } else { i64(-3) }
	}
	if source >= vertices { return -3 }
	mut edge := usize(0)
	for edge < edge_count {
		origin := unsafe { edges[3 * edge] }
		destination := unsafe { edges[3 * edge + 1] }
		weight := unsafe { edges[3 * edge + 2] }
		if origin < 0 || destination < 0 || u64(origin) >= u64(vertices) || u64(destination) >= u64(vertices) { return -3 }
		if weight < 0 { return -4 }
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
		mut selected := vertices
		mut best := i64(0)
		vertex = 0
		for vertex < vertices {
			if unsafe { reachable[vertex] } == 1 && (selected == vertices || unsafe { distances[vertex] } < best) {
				selected = vertex
				best = unsafe { distances[vertex] }
			}
			vertex++
		}
		if selected == vertices { break }
		unsafe { reachable[selected] = 2 }
		edge = 0
		for edge < edge_count {
			if usize(unsafe { edges[3 * edge] }) == selected {
				destination := usize(unsafe { edges[3 * edge + 1] })
				weight := unsafe { edges[3 * edge + 2] }
				base := unsafe { distances[selected] }
				if base > i64(9223372036854775807) - weight { return -2 }
				candidate := base + weight
				if unsafe { reachable[destination] } != 2 &&
				   (unsafe { reachable[destination] } == 0 || candidate < unsafe { distances[destination] }) {
					unsafe {
						distances[destination] = candidate
						reachable[destination] = 1
					}
				}
			}
			edge++
		}
		round++
	}
	vertex = 0
	for vertex < vertices {
		if unsafe { reachable[vertex] } == 2 { unsafe { reachable[vertex] = 1 } }
		vertex++
	}
	return 0
}
