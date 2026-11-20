package dijkstra_lazy_heap

import "core:c"

MAX_VERTICES :: 64
MAX_EDGES :: 256
MAX_HEAP :: MAX_EDGES + 1
NONE :: MAX_EDGES

before :: proc(left_distance: i64, left_vertex: int, right_distance: i64, right_vertex: int) -> bool {
	return left_distance < right_distance || (left_distance == right_distance && left_vertex < right_vertex)
}

@(export)
dijkstra_lazy_heap :: proc "c" (edges: [^]i64, vertices: c.size_t, edge_count: c.size_t,
	source: c.size_t, distances: [^]i64, reachable: [^]u8) -> i64 {
	if vertices > c.size_t(MAX_VERTICES) || edge_count > c.size_t(MAX_EDGES) do return -3
	if vertices == 0 do return if source == 0 && edge_count == 0 { 0 } else { -3 }
	if source >= vertices do return -3
	for edge := c.size_t(0); edge < edge_count; edge += 1 {
		origin, destination := edges[3*edge], edges[3*edge+1]
		weight := edges[3*edge+2]
		if origin < 0 || destination < 0 || c.size_t(origin) >= vertices || c.size_t(destination) >= vertices do return -3
		if weight < 0 do return -4
	}

	var head: [MAX_VERTICES]int
	var tail: [MAX_VERTICES]int
	var next: [MAX_EDGES]int
	for vertex := 0; vertex < int(vertices); vertex += 1 { head[vertex], tail[vertex] = NONE, NONE }
	for edge := 0; edge < int(edge_count); edge += 1 {
		origin := int(edges[3*edge])
		next[edge] = NONE
		if head[origin] == NONE { head[origin] = edge }
		else { next[tail[origin]] = edge }
		tail[origin] = edge
	}

	for vertex := 0; vertex < int(vertices); vertex += 1 {
		distances[vertex] = 0
		reachable[vertex] = 0
	}
	var heap_distance: [MAX_HEAP]i64
	var heap_vertex: [MAX_HEAP]int
	heap_count := 1
	heap_distance[0], heap_vertex[0] = 0, int(source)
	distances[source] = 0
	reachable[source] = 1

	for heap_count > 0 {
		current, origin := heap_distance[0], heap_vertex[0]
		heap_count -= 1
		if heap_count > 0 {
			last_distance, last_vertex := heap_distance[heap_count], heap_vertex[heap_count]
			position := 0
			for 2*position+1 < heap_count {
				child := 2*position+1
				if child+1 < heap_count && before(heap_distance[child+1], heap_vertex[child+1], heap_distance[child], heap_vertex[child]) { child += 1 }
				if !before(heap_distance[child], heap_vertex[child], last_distance, last_vertex) { break }
				heap_distance[position], heap_vertex[position] = heap_distance[child], heap_vertex[child]
				position = child
			}
			heap_distance[position], heap_vertex[position] = last_distance, last_vertex
		}
		if current != distances[origin] || reachable[origin] == 2 { continue }
		reachable[origin] = 2
		for edge := head[origin]; edge != NONE; edge = next[edge] {
			destination := int(edges[3*edge+1])
			weight := edges[3*edge+2]
			if current > 9223372036854775807-weight do return -2
			candidate := current + weight
			if reachable[destination] != 2 && (reachable[destination] == 0 || candidate < distances[destination]) {
				distances[destination] = candidate
				reachable[destination] = 1
				position := heap_count
				heap_count += 1
				for position > 0 {
					parent := (position - 1) / 2
					if !before(candidate, destination, heap_distance[parent], heap_vertex[parent]) { break }
					heap_distance[position], heap_vertex[position] = heap_distance[parent], heap_vertex[parent]
					position = parent
				}
				heap_distance[position], heap_vertex[position] = candidate, destination
			}
		}
	}
	for vertex := 0; vertex < int(vertices); vertex += 1 {
		if reachable[vertex] == 2 { reachable[vertex] = 1 }
	}
	return 0
}
