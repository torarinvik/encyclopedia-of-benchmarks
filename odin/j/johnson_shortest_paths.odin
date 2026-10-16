package johnson_shortest_paths

import "core:c"

MAX_VERTICES :: 32
MAX_EDGES :: 256
MAX_INPUT_LENGTH :: 770
MAX_QUEUE :: MAX_EDGES + 1
UNREACHABLE :: i64(0x7fffffffffffffff)
UNREACHABLE_SENTINEL :: i64(0x4000000000000000)
FNV_OFFSET_BASIS :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

fnv_word :: proc "contextless" (hash: u64, value: i64) -> u64 {
	bits := u64(value)
	result := hash
	for byte := 0; byte < 8; byte += 1 {
		result = (result ^ ((bits >> (8 * byte)) & 255)) * FNV_PRIME
	}
	return result
}

@(export)
johnson_shortest_paths :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	vertex_value, edge_value := input[0], input[1]
	if vertex_value < 1 || vertex_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES do return -1
	vertices, edges := int(vertex_value), int(edge_value)
	if length != c.size_t(2 + 3 * edges) do return -1

	var edge_from: [MAX_EDGES]int
	var edge_to: [MAX_EDGES]int
	var edge_weight: [MAX_EDGES]i64
	for edge := 0; edge < edges; edge += 1 {
		from_value, to_value, weight := input[2 + 3 * edge], input[3 + 3 * edge], input[4 + 3 * edge]
		if from_value < 1 || from_value > vertex_value || to_value < 1 || to_value > vertex_value || weight < -32 || weight > 32 do return -1
		edge_from[edge], edge_to[edge], edge_weight[edge] = int(from_value - 1), int(to_value - 1), weight
	}

	var potential: [MAX_VERTICES]i64
	for iteration := 1; iteration < vertices; iteration += 1 {
		updated := false
		for edge := 0; edge < edges; edge += 1 {
			from, to := edge_from[edge], edge_to[edge]
			candidate := potential[from] + edge_weight[edge]
			if candidate < potential[to] { potential[to] = candidate; updated = true }
		}
		if !updated do break
	}
	for edge := 0; edge < edges; edge += 1 {
		if potential[edge_from[edge]] + edge_weight[edge] < potential[edge_to[edge]] do return -1
	}

	result := FNV_OFFSET_BASIS
	for source := 0; source < vertices; source += 1 {
		var distance: [MAX_VERTICES]i64
		var visited: [MAX_VERTICES]bool
		for vertex := 0; vertex < vertices; vertex += 1 { distance[vertex] = UNREACHABLE }
		distance[source] = 0
		var queue_vertices: [MAX_QUEUE]int
		var queue_distances: [MAX_QUEUE]i64
		queue_length := 1
		queue_vertices[0], queue_distances[0] = source, 0
		for queue_length > 0 {
			minimum := 0
			for index := 1; index < queue_length; index += 1 {
				if queue_distances[index] < queue_distances[minimum] do minimum = index
			}
			current := queue_vertices[minimum]
			for index := minimum + 1; index < queue_length; index += 1 {
				queue_vertices[index - 1], queue_distances[index - 1] = queue_vertices[index], queue_distances[index]
			}
			queue_length -= 1
			if visited[current] do continue
			visited[current] = true

			for edge := 0; edge < edges; edge += 1 {
				if edge_from[edge] != current do continue
				next := edge_to[edge]
				reweighted := edge_weight[edge] + potential[current] - potential[next]
				candidate := distance[current] + reweighted
				if !visited[next] && candidate < distance[next] {
					distance[next] = candidate
					queue_vertices[queue_length], queue_distances[queue_length] = next, candidate
					queue_length += 1
				}
			}
		}

		for destination := 0; destination < vertices; destination += 1 {
			output := UNREACHABLE_SENTINEL
			if distance[destination] != UNREACHABLE { output = distance[destination] - potential[source] + potential[destination] }
			result = fnv_word(result, output)
		}
	}
	return i64(result & 0x7fffffffffffffff)
}
