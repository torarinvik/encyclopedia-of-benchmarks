package bidirectional_dijkstra

import "core:c"

MAX_VERTICES :: 64
MAX_EDGES :: 256
MAX_WEIGHT :: 1_000_000
INF :: i64(1_000_000_000)

@(export)
bidirectional_dijkstra :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 do return -1
	nv, mv, source_v, target_v := input[0], input[1], input[2], input[3]
	if nv < 1 || nv > MAX_VERTICES || mv < 0 || mv > MAX_EDGES do return -1
	if source_v < 0 || source_v >= nv || target_v < 0 || target_v >= nv do return -1
	n, m := int(nv), int(mv)
	if length != c.size_t(4 + 3 * m) do return -1
	for edge := 0; edge < m; edge += 1 {
		from, to, weight := input[4 + 3 * edge], input[5 + 3 * edge], input[6 + 3 * edge]
		if from < 0 || from >= nv || to < 0 || to >= nv || weight < 0 || weight > MAX_WEIGHT do return -1
	}
	source, target := int(source_v), int(target_v)
	if source == target do return 0

	var forward: [MAX_VERTICES]i64
	var backward: [MAX_VERTICES]i64
	var settled_forward: [MAX_VERTICES]bool
	var settled_backward: [MAX_VERTICES]bool
	for vertex := 0; vertex < n; vertex += 1 {
		forward[vertex] = INF
		backward[vertex] = INF
	}
	forward[source] = 0
	backward[target] = 0
	best := INF

	for step := 0; step < 2 * n; step += 1 {
		next_forward, next_backward := n, n
		min_forward, min_backward := INF, INF
		for vertex := 0; vertex < n; vertex += 1 {
			if !settled_forward[vertex] && forward[vertex] < min_forward {
				min_forward, next_forward = forward[vertex], vertex
			}
			if !settled_backward[vertex] && backward[vertex] < min_backward {
				min_backward, next_backward = backward[vertex], vertex
			}
		}
		if next_forward == n || next_backward == n do break
		if best != INF && min_forward + min_backward >= best do break

		if min_forward <= min_backward {
			current := next_forward
			settled_forward[current] = true
			if backward[current] != INF && forward[current] + backward[current] < best {
				best = forward[current] + backward[current]
			}
			for edge := 0; edge < m; edge += 1 {
				if input[4 + 3 * edge] != i64(current) do continue
				to := int(input[5 + 3 * edge])
				candidate := forward[current] + input[6 + 3 * edge]
				if !settled_forward[to] && candidate < forward[to] do forward[to] = candidate
				if backward[to] != INF && candidate + backward[to] < best do best = candidate + backward[to]
			}
		} else {
			current := next_backward
			settled_backward[current] = true
			if forward[current] != INF && forward[current] + backward[current] < best {
				best = forward[current] + backward[current]
			}
			for edge := 0; edge < m; edge += 1 {
				if input[5 + 3 * edge] != i64(current) do continue
				from := int(input[4 + 3 * edge])
				candidate := backward[current] + input[6 + 3 * edge]
				if !settled_backward[from] && candidate < backward[from] do backward[from] = candidate
				if forward[from] != INF && forward[from] + input[6 + 3 * edge] + backward[current] < best {
					best = forward[from] + input[6 + 3 * edge] + backward[current]
				}
			}
		}
	}
	if best == INF do return -1
	return best
}
