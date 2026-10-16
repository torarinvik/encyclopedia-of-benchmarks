package breadth_first_search_shortest_path_distance

import "core:c"

MAX_VERTICES :: 26
MAX_EDGES :: 256

@(export)
breadth_first_search_shortest_path_distance :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 do return -1
	nv, mv, source_value, target_value := input[0], input[1], input[2], input[3]
	if nv < 1 || nv > MAX_VERTICES || mv < 0 || mv > MAX_EDGES do return -1
	n, edges := int(nv), int(mv)
	if source_value < 0 || source_value >= nv || target_value < 0 || target_value >= nv ||
		length != c.size_t(4 + 2 * edges) do return -1

	var adjacent: [MAX_VERTICES * MAX_VERTICES]bool
	for edge := 0; edge < edges; edge += 1 {
		from_value, to_value := input[4 + 2 * edge], input[5 + 2 * edge]
		if from_value < 0 || from_value >= nv || to_value < 0 || to_value >= nv do return -1
		adjacent[int(from_value) * n + int(to_value)] = true
	}

	source, target := int(source_value), int(target_value)
	var distance: [MAX_VERTICES]i64
	var queue: [MAX_VERTICES]int
	for vertex := 0; vertex < n; vertex += 1 do distance[vertex] = -1
	head, tail := 0, 1
	distance[source] = 0
	queue[0] = source
	for head < tail {
		current := queue[head]
		head += 1
		for next := 0; next < n; next += 1 {
			if adjacent[current * n + next] && distance[next] < 0 {
				distance[next] = distance[current] + 1
				queue[tail] = next
				tail += 1
			}
		}
	}
	return distance[target]
}
