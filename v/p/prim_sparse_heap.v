module prim_sparse_heap

const max_vertices = 64
const max_edges = 4096
const max_arcs = 2 * max_edges
const none_vertex = max_vertices
const no_arc = max_arcs

fn before(best &[64]i64, left int, right int) bool {
	return best[left] < best[right] || (best[left] == best[right] && left < right)
}

fn exchange(mut heap [64]int, mut position [64]int, first int, second int) {
	heap[first], heap[second] = heap[second], heap[first]
	position[heap[first]] = first
	position[heap[second]] = second
}

fn sift_up(mut heap [64]int, mut position [64]int, best &[64]i64, start int) {
	mut at := start
	for at > 0 {
		parent := (at - 1) / 2
		if !before(best, heap[at], heap[parent]) { break }
		exchange(mut heap, mut position, at, parent)
		at = parent
	}
}

fn pop_min(mut heap [64]int, mut position [64]int, mut count int, best &[64]i64) int {
	result := heap[0]
	position[result] = none_vertex
	count--
	if count > 0 {
		heap[0] = heap[count]
		position[heap[0]] = 0
		mut at := 0
		for 2 * at + 1 < count {
			mut child := 2 * at + 1
			if child + 1 < count && before(best, heap[child + 1], heap[child]) { child++ }
			if !before(best, heap[child], heap[at]) { break }
			exchange(mut heap, mut position, at, child)
			at = child
		}
	}
	return result
}

@[export: 'prim_sparse_heap']
pub fn prim_sparse_heap(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > 12290 { return -2 }
		if values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 4096 { return -2 }
		vertices, edge_count := int(values[0]), int(values[1])
		if length != usize(2 + 3 * edge_count) || (vertices == 0 && edge_count != 0) { return -2 }
		if vertices == 0 { return 0 }
		for edge in 0 .. edge_count {
			origin, destination := values[2 + 3 * edge], values[3 + 3 * edge]
			weight := values[4 + 3 * edge]
			if origin < 0 || destination < 0 || origin >= i64(vertices) || destination >= i64(vertices) || weight < 0 || weight > 2147483647 { return -2 }
		}

		mut head := [max_vertices]int{}
		mut next := [max_arcs]int{}
		mut to := [max_arcs]int{}
		mut arc_weight := [max_arcs]i64{}
		for vertex in 0 .. vertices { head[vertex] = no_arc }
		mut arc_count := 0
		for edge in 0 .. edge_count {
			origin, destination := int(values[2 + 3 * edge]), int(values[3 + 3 * edge])
			weight := values[4 + 3 * edge]
			if origin == destination { continue }
			to[arc_count], arc_weight[arc_count] = destination, weight
			next[arc_count], head[origin] = head[origin], arc_count
			arc_count++
			to[arc_count], arc_weight[arc_count] = origin, weight
			next[arc_count], head[destination] = head[destination], arc_count
			arc_count++
		}

		mut best := [max_vertices]i64{}
		mut has_best := [max_vertices]bool{}
		mut selected := [max_vertices]bool{}
		mut heap := [max_vertices]int{}
		mut position := [max_vertices]int{}
		for vertex in 0 .. vertices { position[vertex] = none_vertex }
		heap[0], position[0], has_best[0] = 0, 0, true
		mut heap_count, mut selected_count := 1, 0
		mut total := i64(0)
		for heap_count > 0 {
			origin := pop_min(mut heap, mut position, mut heap_count, best)
			selected[origin] = true
			selected_count++
			total += best[origin]
			mut arc := head[origin]
			for arc != no_arc {
				destination := to[arc]
				if !selected[destination] && (!has_best[destination] || arc_weight[arc] < best[destination]) {
					best[destination], has_best[destination] = arc_weight[arc], true
					if position[destination] == none_vertex {
						heap[heap_count] = destination
						position[destination] = heap_count
						heap_count++
					}
					sift_up(mut heap, mut position, best, position[destination])
				}
				arc = next[arc]
			}
		}
		return if selected_count == vertices { total } else { i64(-1) }
	}
}
