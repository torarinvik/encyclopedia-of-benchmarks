module dijkstra_lazy_heap

const max_vertices = 64
const max_edges = 256
const max_heap = max_edges + 1
const none_index = max_edges

fn before(left_distance i64, left_vertex int, right_distance i64, right_vertex int) bool {
	return left_distance < right_distance || (left_distance == right_distance && left_vertex < right_vertex)
}

@[export: 'dijkstra_lazy_heap']
pub fn dijkstra_lazy_heap(edges &i64, vertices usize, edge_count usize, source usize,
	mut distances &i64, mut reachable &u8) i64 {
	unsafe {
		if vertices > usize(max_vertices) || edge_count > usize(max_edges) { return -3 }
		if vertices == 0 { return if source == 0 && edge_count == 0 { i64(0) } else { i64(-3) } }
		if source >= vertices { return -3 }
		for edge in 0 .. edge_count {
			origin, destination, weight := edges[3 * edge], edges[3 * edge + 1], edges[3 * edge + 2]
			if origin < 0 || destination < 0 || u64(origin) >= u64(vertices) || u64(destination) >= u64(vertices) { return -3 }
			if weight < 0 { return -4 }
		}

		mut head := [max_vertices]int{}
		mut tail := [max_vertices]int{}
		mut next := [max_edges]int{}
		for vertex in 0 .. int(vertices) { head[vertex], tail[vertex] = none_index, none_index }
		for edge in 0 .. int(edge_count) {
			origin := int(edges[3 * edge])
			next[edge] = none_index
			if head[origin] == none_index { head[origin] = edge } else { next[tail[origin]] = edge }
			tail[origin] = edge
		}

		for vertex in 0 .. int(vertices) {
			distances[vertex] = 0
			reachable[vertex] = 0
		}
		mut heap_distance := [max_heap]i64{}
		mut heap_vertex := [max_heap]int{}
		mut heap_count := 1
		heap_distance[0], heap_vertex[0] = 0, int(source)
		distances[source] = 0
		reachable[source] = 1

		for heap_count > 0 {
			current, origin := heap_distance[0], heap_vertex[0]
			heap_count--
			if heap_count > 0 {
				last_distance, last_vertex := heap_distance[heap_count], heap_vertex[heap_count]
				mut position := 0
				for 2 * position + 1 < heap_count {
					mut child := 2 * position + 1
					if child + 1 < heap_count && before(heap_distance[child + 1], heap_vertex[child + 1], heap_distance[child], heap_vertex[child]) { child++ }
					if !before(heap_distance[child], heap_vertex[child], last_distance, last_vertex) { break }
					heap_distance[position], heap_vertex[position] = heap_distance[child], heap_vertex[child]
					position = child
				}
				heap_distance[position], heap_vertex[position] = last_distance, last_vertex
			}
			if current != distances[origin] || reachable[origin] == 2 { continue }
			reachable[origin] = 2
			mut edge := head[origin]
			for edge != none_index {
				destination := int(edges[3 * edge + 1])
				weight := edges[3 * edge + 2]
				if current > i64(9223372036854775807) - weight { return -2 }
				candidate := current + weight
				if reachable[destination] != 2 && (reachable[destination] == 0 || candidate < distances[destination]) {
					distances[destination] = candidate
					reachable[destination] = 1
					mut position := heap_count
					heap_count++
					for position > 0 {
						parent := (position - 1) / 2
						if !before(candidate, destination, heap_distance[parent], heap_vertex[parent]) { break }
						heap_distance[position], heap_vertex[position] = heap_distance[parent], heap_vertex[parent]
						position = parent
					}
					heap_distance[position], heap_vertex[position] = candidate, destination
				}
				edge = next[edge]
			}
		}
		for vertex in 0 .. int(vertices) { if reachable[vertex] == 2 { reachable[vertex] = 1 } }
		return 0
	}
}
