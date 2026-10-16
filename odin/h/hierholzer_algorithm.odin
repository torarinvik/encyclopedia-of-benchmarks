package hierholzer_algorithm

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 256
MAX_INPUT_LENGTH :: 2 + 2 * MAX_EDGES
MAX_INCIDENCES :: 2 * MAX_EDGES
FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

fnv_word :: proc "contextless" (hash: u64, value: i64) -> u64 {
	bits := transmute(u64)value
	result := hash
	for byte := 0; byte < 8; byte += 1 {
		result = (result ^ ((bits >> u64(8 * byte)) & 255)) * FNV_PRIME
	}
	return result
}

record_hash :: proc "contextless" (has_circuit: i64, route: [^]int, route_count: int) -> i64 {
	hash := fnv_word(FNV_OFFSET, has_circuit)
	hash = fnv_word(hash, i64(route_count))
	for i := 0; i < route_count; i += 1 {
		hash = fnv_word(hash, i64(route[route_count - 1 - i]))
	}
	return i64(hash & 0x7fffffffffffffff)
}

@(export)
hierholzer_algorithm :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	n64, m64 := input[0], input[1]
	if n64 < 0 || n64 > MAX_VERTICES || m64 < 0 || m64 > MAX_EDGES do return -1
	n, m := int(n64), int(m64)
	if (n == 0 && m != 0) || length != c.size_t(2 + 2 * m) do return -1

	var adjacency: [MAX_VERTICES][MAX_INCIDENCES]int
	var degree: [MAX_VERTICES]int
	for edge := 0; edge < m; edge += 1 {
		u64, v64 := input[2 + 2 * edge], input[3 + 2 * edge]
		if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 do return -1
		u, v := int(u64), int(v64)
		adjacency[u][degree[u]] = v
		degree[u] += 1
		adjacency[v][degree[v]] = u
		degree[v] += 1
	}

	odd_count := 0
	first_nonempty := -1
	for vertex := 0; vertex < n; vertex += 1 {
		if degree[vertex] > 0 && first_nonempty < 0 do first_nonempty = vertex
		if degree[vertex] % 2 != 0 do odd_count += 1
	}
	if odd_count != 0 {
		var empty_route: [MAX_INCIDENCES + 1]int
		return record_hash(0, &empty_route, 0)
	}
	if n == 0 {
		var empty_route: [MAX_INCIDENCES + 1]int
		return record_hash(1, &empty_route, 0)
	}
	if first_nonempty < 0 {
		var empty_route: [MAX_INCIDENCES + 1]int
		empty_route[0] = 0
		return record_hash(1, &empty_route, 1)
	}

	var reached: [MAX_VERTICES]bool
	var queue: [MAX_VERTICES]int
	q_head, q_tail := 0, 0
	queue[q_tail] = first_nonempty
	q_tail += 1
	reached[first_nonempty] = true
	for q_head < q_tail {
		u := queue[q_head]
		q_head += 1
		for i := 0; i < degree[u]; i += 1 {
			v := adjacency[u][i]
			if !reached[v] {
				reached[v] = true
				queue[q_tail] = v
				q_tail += 1
			}
		}
	}
	for vertex := 0; vertex < n; vertex += 1 {
		if degree[vertex] > 0 && !reached[vertex] {
			var empty_route: [MAX_INCIDENCES + 1]int
			return record_hash(0, &empty_route, 0)
		}
	}

	var stack: [MAX_INCIDENCES + 1]int
	var route_reverse: [MAX_INCIDENCES + 1]int
	top := 1
	stack[0] = first_nonempty
	route_count := 0
	for top > 0 {
		u := stack[top - 1]
		if degree[u] > 0 {
			v := adjacency[u][0]
			for i := 1; i < degree[u]; i += 1 { adjacency[u][i - 1] = adjacency[u][i] }
			degree[u] -= 1
			reciprocal := -1
			for i := 0; i < degree[v]; i += 1 {
				if adjacency[v][i] == u { reciprocal = i; break }
			}
			if reciprocal < 0 do return -1
			for i := reciprocal + 1; i < degree[v]; i += 1 { adjacency[v][i - 1] = adjacency[v][i] }
			degree[v] -= 1
			stack[top] = v
			top += 1
		} else {
			top -= 1
			route_reverse[route_count] = u
			route_count += 1
		}
	}
	if route_count != m + 1 {
		var empty_route: [MAX_INCIDENCES + 1]int
		return record_hash(0, &empty_route, 0)
	}
	return record_hash(1, &route_reverse, route_count)
}
