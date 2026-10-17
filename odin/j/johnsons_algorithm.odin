package johnsons_algorithm

import "core:c"

MAX_VERTICES :: 16
MAX_INPUT_LENGTH :: 1 + MAX_VERTICES * MAX_VERTICES
MAX_WEIGHT :: i64(32)
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
johnsons_algorithm :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	vertex_value := input[0]
	if vertex_value < 1 || vertex_value > MAX_VERTICES do return -1
	vertices := int(vertex_value)
	if length != c.size_t(1 + vertices * vertices) do return -1

	var weight: [MAX_VERTICES][MAX_VERTICES]i64
	var edge: [MAX_VERTICES][MAX_VERTICES]bool
	var reachable: [MAX_VERTICES][MAX_VERTICES]bool
	for from := 0; from < vertices; from += 1 {
		reachable[from][from] = true
		for to := 0; to < vertices; to += 1 {
			value := input[1 + from * vertices + to]
			if value < -MAX_WEIGHT || value > MAX_WEIGHT do return -1
			if from != to && value != 0 {
				edge[from][to] = true
				weight[from][to] = value
				reachable[from][to] = true
			}
		}
	}
	for intermediate := 0; intermediate < vertices; intermediate += 1 {
		for from := 0; from < vertices; from += 1 {
			for to := 0; to < vertices; to += 1 {
				reachable[from][to] = reachable[from][to] ||
					(reachable[from][intermediate] && reachable[intermediate][to])
			}
		}
	}
	for from := 0; from < vertices; from += 1 {
		for to := 0; to < vertices; to += 1 {
			if !reachable[from][to] do return -1
		}
	}

	var potential: [MAX_VERTICES]i64
	for iteration := 1; iteration < vertices; iteration += 1 {
		updated := false
		for from := 0; from < vertices; from += 1 {
			for to := 0; to < vertices; to += 1 {
				if !edge[from][to] do continue
				candidate := potential[from] + weight[from][to]
				if candidate < potential[to] {
					potential[to] = candidate
					updated = true
				}
			}
		}
		if !updated do break
	}
	for from := 0; from < vertices; from += 1 {
		for to := 0; to < vertices; to += 1 {
			if !edge[from][to] do continue
			if potential[from] + weight[from][to] < potential[to] ||
				weight[from][to] + potential[from] - potential[to] <= 0 do return -1
		}
	}

	var reweighted: [MAX_VERTICES][MAX_VERTICES]i64
	for from := 0; from < vertices; from += 1 {
		for to := 0; to < vertices; to += 1 {
			if edge[from][to] {
				reweighted[from][to] = weight[from][to] + potential[from] - potential[to]
			}
		}
	}

	result := FNV_OFFSET_BASIS
	for source := 0; source < vertices; source += 1 {
		var distance: [MAX_VERTICES]i64
		var visited: [MAX_VERTICES]bool
		for vertex := 0; vertex < vertices; vertex += 1 { distance[vertex] = UNREACHABLE }
		distance[source] = 0
		for _ := 0; _ < vertices; _ += 1 {
			current := vertices
			for vertex := 0; vertex < vertices; vertex += 1 {
				if !visited[vertex] && (current == vertices || distance[vertex] <= distance[current]) {
					current = vertex
				}
			}
			if current == vertices || distance[current] == UNREACHABLE do break
			visited[current] = true
			for next := 0; next < vertices; next += 1 {
				if !edge[current][next] || visited[next] do continue
				candidate := distance[current] + reweighted[current][next]
				if candidate < distance[next] { distance[next] = candidate }
			}
		}
		for destination := 0; destination < vertices; destination += 1 {
			output := UNREACHABLE_SENTINEL
			if distance[destination] != UNREACHABLE {
				output = distance[destination] - potential[source] + potential[destination]
			}
			result = fnv_word(result, output)
		}
	}
	return i64(result & 0x7fffffffffffffff)
}
