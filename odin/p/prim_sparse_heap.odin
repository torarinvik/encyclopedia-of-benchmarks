package prim_sparse_heap

import "core:c"

MAX_VERTICES :: 64
MAX_EDGES :: 4096
MAX_ARCS :: 2 * MAX_EDGES
NONE :: MAX_VERTICES
NO_ARC :: MAX_ARCS

before :: proc "contextless" (best: [^]i64, left, right: int) -> bool {
	return best[left] < best[right] || (best[left] == best[right] && left < right)
}

exchange :: proc "contextless" (heap, position: [^]int, first, second: int) {
	saved := heap[first]
	heap[first], heap[second] = heap[second], saved
	position[heap[first]] = first
	position[heap[second]] = second
}

sift_up :: proc "contextless" (heap, position: [^]int, best: [^]i64, start: int) {
	at := start
	for at > 0 {
		parent := (at - 1) / 2
		if !before(best, heap[at], heap[parent]) do break
		exchange(heap, position, at, parent)
		at = parent
	}
}

pop_min :: proc "contextless" (heap, position: [^]int, count: ^int, best: [^]i64) -> int {
	result := heap[0]
	position[result] = NONE
	count^ -= 1
	if count^ > 0 {
		heap[0] = heap[count^]
		position[heap[0]] = 0
		at := 0
		for 2 * at + 1 < count^ {
			child := 2 * at + 1
			if child + 1 < count^ && before(best, heap[child + 1], heap[child]) do child += 1
			if !before(best, heap[child], heap[at]) do break
			exchange(heap, position, at, child)
			at = child
		}
	}
	return result
}

@(export)
prim_sparse_heap :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 12290 do return -2
	if values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 4096 do return -2
	vertices := int(values[0])
	edge_count := int(values[1])
	if int(length) != 2 + 3 * edge_count || (vertices == 0 && edge_count != 0) do return -2
	if vertices == 0 do return 0
	for edge := 0; edge < edge_count; edge += 1 {
		origin, destination := values[2 + 3 * edge], values[3 + 3 * edge]
		weight := values[4 + 3 * edge]
		if origin < 0 || destination < 0 || origin >= i64(vertices) || destination >= i64(vertices) || weight < 0 || weight > 2147483647 do return -2
	}

	var head: [MAX_VERTICES]int
	var next: [MAX_ARCS]int
	var to: [MAX_ARCS]int
	var arc_weight: [MAX_ARCS]i64
	for vertex := 0; vertex < vertices; vertex += 1 { head[vertex] = NO_ARC }
	arc_count := 0
	for edge := 0; edge < edge_count; edge += 1 {
		origin, destination := int(values[2 + 3 * edge]), int(values[3 + 3 * edge])
		weight := values[4 + 3 * edge]
		if origin == destination do continue
		to[arc_count], arc_weight[arc_count] = destination, weight
		next[arc_count], head[origin] = head[origin], arc_count
		arc_count += 1
		to[arc_count], arc_weight[arc_count] = origin, weight
		next[arc_count], head[destination] = head[destination], arc_count
		arc_count += 1
	}

	var best: [MAX_VERTICES]i64
	var has_best: [MAX_VERTICES]bool
	var selected: [MAX_VERTICES]bool
	var heap: [MAX_VERTICES]int
	var position: [MAX_VERTICES]int
	for vertex := 0; vertex < vertices; vertex += 1 { position[vertex] = NONE }
	heap[0], position[0], has_best[0] = 0, 0, true
	heap_count, selected_count := 1, 0
	total := i64(0)
	for heap_count > 0 {
		origin := pop_min(&heap[0], &position[0], &heap_count, &best[0])
		selected[origin] = true
		selected_count += 1
		total += best[origin]
		for arc := head[origin]; arc != NO_ARC; arc = next[arc] {
			destination := to[arc]
			if selected[destination] || (has_best[destination] && arc_weight[arc] >= best[destination]) do continue
			best[destination], has_best[destination] = arc_weight[arc], true
			if position[destination] == NONE {
				heap[heap_count] = destination
				position[destination] = heap_count
				heap_count += 1
			}
			sift_up(&heap[0], &position[0], &best[0], position[destination])
		}
	}
	return if selected_count == vertices { total } else { -1 }
}
