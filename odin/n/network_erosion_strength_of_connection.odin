package network_erosion_strength_of_connection

import "core:c"

SOC_MAX_VERTICES :: 8
SOC_MAX_PARSEABLE_INPUT :: 117
SOC_OUTPUT_BYTES :: 16

soc_shortest_path :: proc(adjacency: []i64, n, source, target: int, path: []int) -> int {
	distance: [SOC_MAX_VERTICES]int
	predecessor: [SOC_MAX_VERTICES]int
	queue: [SOC_MAX_VERTICES]int
	for vertex := 0; vertex < n; vertex += 1 {
		distance[vertex] = -1
		predecessor[vertex] = -1
	}
	head, tail := 0, 1
	queue[0] = source
	distance[source] = 0
	for head < tail {
		vertex := queue[head]
		head += 1
		for successor := 0; successor < n; successor += 1 {
			bit := i64(1) << successor
			if adjacency[vertex]&bit != 0 && distance[successor] == -1 {
				distance[successor] = distance[vertex] + 1
				predecessor[successor] = vertex
				queue[tail] = successor
				tail += 1
			}
		}
	}
	if distance[target] == -1 do return 0
	reversed: [SOC_MAX_VERTICES]int
	count := 0
	vertex := target
	for {
		reversed[count] = vertex
		count += 1
		if vertex == source do break
		vertex = predecessor[vertex]
		if vertex < 0 do return 0
	}
	for index := 0; index < count; index += 1 do path[index] = reversed[count-index-1]
	return count
}

soc_gcd :: proc(left_value, right_value: i64) -> i64 {
	left, right := left_value, right_value
	for right != 0 {
		remainder := left % right
		left, right = right, remainder
	}
	return left
}

soc_write_i64 :: proc(output: [^]u8, word: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 do output[word*8+byte] = u8(bits >> (byte*8))
}

@(export)
network_erosion_strength_of_connection :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > SOC_MAX_PARSEABLE_INPUT do return -1
	vertex_raw, edge_raw := input[0], input[1]
	source_raw, target_raw := input[2], input[3]
	if vertex_raw < 2 || vertex_raw > SOC_MAX_VERTICES || edge_raw < 0 ||
		edge_raw > vertex_raw*(vertex_raw-1) || source_raw < 0 || source_raw >= vertex_raw ||
		target_raw < 0 || target_raw >= vertex_raw || source_raw == target_raw do return -1
	n, edge_count := int(vertex_raw), int(edge_raw)
	source, target := int(source_raw), int(target_raw)
	if length != c.size_t(4 + 2*edge_count) do return -1

	adjacency: [SOC_MAX_VERTICES]i64
	cursor := c.size_t(4)
	for _ := 0; _ < edge_count; _ += 1 {
		from_raw, to_raw := input[cursor], input[cursor+1]
		cursor += 2
		if from_raw < 0 || from_raw >= vertex_raw || to_raw < 0 || to_raw >= vertex_raw || from_raw == to_raw do return -1
		from, to := int(from_raw), int(to_raw)
		bit := i64(1) << to
		if adjacency[from]&bit != 0 do return -1
		adjacency[from] |= bit
	}

	distances: [SOC_MAX_VERTICES]int
	for vertex := 0; vertex < n; vertex += 1 do distances[vertex] = -1
	path: [SOC_MAX_VERTICES]int
	first_count := soc_shortest_path(adjacency[:n], n, source, target, path[:])
	if first_count != 0 {
		initial_length := first_count - 1
		distances[source], distances[target] = initial_length, initial_length
		for {
			path_count := soc_shortest_path(adjacency[:n], n, source, target, path[:])
			if path_count == 0 do break
			path_length := path_count - 1
			if path_length == 1 {
				adjacency[source] &= ~(i64(1) << target)
				continue
			}
			for index := 0; index < path_count; index += 1 {
				vertex := path[index]
				if distances[vertex] == -1 do distances[vertex] = path_length
			}
			for index := 1; index < path_count-1; index += 1 {
				vertex := path[index]
				bit := i64(1) << vertex
				adjacency[vertex] = 0
				for other := 0; other < n; other += 1 do adjacency[other] &= ~bit
			}
		}
	}

	reciprocal_sum_scaled: i64 = 0
	for vertex := 0; vertex < n; vertex += 1 {
		if distances[vertex] >= 1 do reciprocal_sum_scaled += 420 / distances[vertex]
	}
	numerator := 2 * reciprocal_sum_scaled
	denominator := i64(420 * (n + 2))
	if numerator == 0 {
		denominator = 1
	} else {
		divisor := soc_gcd(numerator, denominator)
		numerator /= divisor
		denominator /= divisor
	}
	if output == nil || capacity < SOC_OUTPUT_BYTES do return -2
	soc_write_i64(output, 0, numerator)
	soc_write_i64(output, 1, denominator)
	return SOC_OUTPUT_BYTES
}
