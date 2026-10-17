module kahns_algorithm_long

@[export: 'kahns_algorithm_long']
pub fn kahns_algorithm_long(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > 258 { return -1 }
	vertex_count := values[0]
	edge_count := values[1]
	if vertex_count < 1 || vertex_count > 32 || edge_count < 0 || edge_count > 128 { return -1 }
	if length != usize(2 + 2 * edge_count) { return -1 }

	mut multiplicity := [1024]i64{}
	mut indegree := [32]i64{}
	mut distance := [32]i64{}
	mut queue := [32]i64{}
	unsafe {
		for vertex in 0 ..< int(vertex_count) { distance[vertex] = 1 }
		for edge in 0 ..< int(edge_count) {
			source := values[2 + 2 * edge]
			destination := values[3 + 2 * edge]
			if source < 0 || source >= vertex_count || destination < 0 || destination >= vertex_count { return -1 }
			multiplicity[int(source * 32 + destination)]++
			indegree[int(destination)]++
		}
	}

	mut head := 0
	mut tail := 0
	unsafe {
		for vertex in 0 ..< int(vertex_count) {
			if indegree[vertex] == 0 { queue[tail] = i64(vertex); tail++ }
		}
	}
	mut processed := i64(0)
	mut maximum := i64(1)
	for head < tail {
		source := int(queue[head])
		head++
		processed++
		unsafe {
			if distance[source] > maximum { maximum = distance[source] }
		for destination in 0 ..< int(vertex_count) {
				copies := multiplicity[source * 32 + destination]
				if copies == 0 { continue }
				candidate := distance[source] + 1
				if candidate > distance[destination] { distance[destination] = candidate }
				for _ in 0 ..< int(copies) {
					indegree[destination]--
					if indegree[destination] == 0 { queue[tail] = i64(destination); tail++ }
				}
			}
		}
	}
	if processed != vertex_count { return -1 }
	unsafe {
		for vertex in 0 ..< int(vertex_count) {
			if distance[vertex] > maximum { maximum = distance[vertex] }
		}
	}
	return maximum
}
