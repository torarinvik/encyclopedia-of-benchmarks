package hub_labeling_pruned

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 28
MAX_INPUT :: 66
MAX_FIELDS :: 73
MAX_OUTPUT_BYTES :: 8 * MAX_FIELDS

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

unique_shortest_paths :: proc(adjacency: [^]bool, n: int) -> bool {
	for source := 0; source < n; source += 1 {
		distance: [MAX_VERTICES]i16
		ways: [MAX_VERTICES]u8
		queue: [MAX_VERTICES]int
		for i := 0; i < n; i += 1 { distance[i] = -1 }
		head, tail := 0, 0
		distance[source] = 0; ways[source] = 1; queue[tail] = source; tail += 1
		for head < tail {
			vertex := queue[head]; head += 1
			for neighbor := 0; neighbor < n; neighbor += 1 {
				if !adjacency[vertex*MAX_VERTICES+neighbor] do continue
				if distance[neighbor] < 0 {
					distance[neighbor] = distance[vertex] + 1
					ways[neighbor] = ways[vertex]
					queue[tail] = neighbor; tail += 1
				} else if distance[neighbor] == distance[vertex] + 1 {
					sum := int(ways[neighbor]) + int(ways[vertex])
					ways[neighbor] = u8(min(2, sum))
				}
			}
		}
		for vertex := 0; vertex < n; vertex += 1 { if ways[vertex] != 1 do return false }
	}
	return true
}

@(export)
hub_labeling_pruned :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	if input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES do return -1
	n, m := int(input[0]), int(input[1])
	if length != c.size_t(2+n+2*m) do return -1
	seen_order: [MAX_VERTICES]bool
	for i := 0; i < n; i += 1 {
		vertex := input[2+i]
		if vertex < 0 || vertex >= i64(n) || seen_order[int(vertex)] do return -1
		seen_order[int(vertex)] = true
	}
	adjacency: [MAX_VERTICES*MAX_VERTICES]bool
	previous_left, previous_right := i64(-1), i64(-1)
	for edge := 0; edge < m; edge += 1 {
		left, right := input[2+n+2*edge], input[3+n+2*edge]
		if left < 0 || right <= left || right >= i64(n) || left < previous_left || (left == previous_left && right <= previous_right) do return -1
		previous_left, previous_right = left, right
		adjacency[int(left)*MAX_VERTICES+int(right)] = true
		adjacency[int(right)*MAX_VERTICES+int(left)] = true
	}
	if !unique_shortest_paths(&adjacency[0], n) do return -1
	labels: [MAX_VERTICES*MAX_VERTICES]i16
	for i := 0; i < MAX_VERTICES*MAX_VERTICES; i += 1 { labels[i] = -1 }
	for order_index := 0; order_index < n; order_index += 1 {
		hub := int(input[2+order_index])
		distance: [MAX_VERTICES]i16
		queue: [MAX_VERTICES]int
		for i := 0; i < n; i += 1 { distance[i] = -1 }
		head, tail := 0, 0
		distance[hub] = 0; queue[tail] = hub; tail += 1
		for head < tail {
			vertex := queue[head]; head += 1
			estimate := i16(2*MAX_VERTICES)
			for common := 0; common < n; common += 1 {
				from_hub := labels[hub*MAX_VERTICES+common]
				from_vertex := labels[vertex*MAX_VERTICES+common]
				if from_hub >= 0 && from_vertex >= 0 && from_hub+from_vertex < estimate { estimate = from_hub + from_vertex }
			}
			if estimate <= distance[vertex] do continue
			labels[vertex*MAX_VERTICES+hub] = distance[vertex]
			for neighbor := 0; neighbor < n; neighbor += 1 {
				if adjacency[vertex*MAX_VERTICES+neighbor] && distance[neighbor] < 0 {
					distance[neighbor] = distance[vertex] + 1
					queue[tail] = neighbor; tail += 1
				}
			}
		}
	}
	fields: [MAX_FIELDS]i64
	field_count := 0
	fields[field_count] = i64(n); field_count += 1
	for vertex := 0; vertex < n; vertex += 1 {
		count_index := field_count; field_count += 1
		count: i64 = 0
		for hub := 0; hub < n; hub += 1 {
			value := labels[vertex*MAX_VERTICES+hub]
			if value >= 0 { fields[field_count] = i64(hub) | (i64(value) << 8); field_count += 1; count += 1 }
		}
		fields[count_index] = count
	}
	bytes := field_count * 8
	if output == nil || capacity < c.size_t(bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8
	for i := 0; i < field_count; i += 1 { store_i64_le(&staged[0], i*8, fields[i]) }
	for i := 0; i < bytes; i += 1 { output[i] = staged[i] }
	return i64(bytes)
}
