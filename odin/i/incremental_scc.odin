package incremental_scc

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 32
MAX_INPUT_LENGTH :: 2 + 2 * MAX_EDGES

@(export)
incremental_scc :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES do return -1
	vertex_count := int(input[0])
	edge_count := int(input[1])
	if length != c.size_t(2 + 2 * edge_count) do return -1

	sources: [MAX_EDGES]int
	destinations: [MAX_EDGES]int
	for edge in 0..<edge_count {
		source := input[2 + 2 * edge]
		destination := input[3 + 2 * edge]
		if source < 0 || destination < 0 || source >= i64(vertex_count) || destination >= i64(vertex_count) do return -1
		sources[edge] = int(source)
		destinations[edge] = int(destination)
	}

	reachable: [MAX_VERTICES * MAX_VERTICES]bool = {}
	for vertex in 0..<vertex_count do reachable[vertex * MAX_VERTICES + vertex] = true
	checksum: i64 = 0
	for edge in 0..<edge_count {
		source := sources[edge]
		destination := destinations[edge]
		predecessors: [MAX_VERTICES]bool
		successors: [MAX_VERTICES]bool
		for vertex in 0..<vertex_count {
			predecessors[vertex] = reachable[vertex * MAX_VERTICES + source]
			successors[vertex] = reachable[destination * MAX_VERTICES + vertex]
		}
		for first in 0..<vertex_count {
			for second in 0..<vertex_count {
				if predecessors[first] && successors[second] do reachable[first * MAX_VERTICES + second] = true
			}
		}

		assigned: [MAX_VERTICES]bool = {}
		component_count := 0
		for first in 0..<vertex_count {
			if assigned[first] do continue
			component_count += 1
			for vertex in first..<vertex_count {
				if reachable[first * MAX_VERTICES + vertex] && reachable[vertex * MAX_VERTICES + first] do assigned[vertex] = true
			}
		}
		checksum += i64(edge + 1) * i64(component_count)
	}
	return checksum
}
