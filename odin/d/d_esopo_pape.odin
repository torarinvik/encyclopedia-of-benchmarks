package d_esopo_pape

import "core:c"

MAX_VERTICES :: 16
MAX_EDGES :: 64
MAX_INPUT_LENGTH :: 3 + 3 * MAX_EDGES

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u32(byte * 8)) & 255)
	}
}

@(export)
d_esopo_pape :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	raw_n, raw_m, raw_source := values[0], values[1], values[2]
	if raw_n < 1 || raw_n > MAX_VERTICES || raw_m < 0 || raw_m > MAX_EDGES ||
		raw_source < 0 || raw_source >= raw_n || length != c.size_t(3 + 3 * raw_m) do return -1
	n, m := int(raw_n), int(raw_m)

	head: [MAX_VERTICES]int
	to: [MAX_EDGES]int
	next: [MAX_EDGES]int
	weight: [MAX_EDGES]i64
	for vertex := 0; vertex < n; vertex += 1 do head[vertex] = -1
	for edge := 0; edge < m; edge += 1 {
		u, v, w := values[3 + 3 * edge], values[4 + 3 * edge], values[5 + 3 * edge]
		if u < 0 || u >= raw_n || v < 0 || v >= raw_n || w < 0 || w > 1000 do return -1
		to[edge], weight[edge] = int(v), w
		next[edge] = head[int(u)]
		head[int(u)] = edge
	}

	distance: [MAX_VERTICES]i64
	reachable: [MAX_VERTICES]bool
	queued: [MAX_VERTICES]bool
	removed_before: [MAX_VERTICES]bool
	deque: [MAX_VERTICES]int
	front, size := 0, 1
	source := int(raw_source)
	deque[0] = source
	distance[source] = 0
	reachable[source], queued[source] = true, true
	for size > 0 {
		vertex := deque[front]
		front = (front + 1) % n
		size -= 1
		queued[vertex], removed_before[vertex] = false, true
		for edge := head[vertex]; edge >= 0; edge = next[edge] {
			neighbor := to[edge]
			candidate := distance[vertex] + weight[edge]
			if !reachable[neighbor] || candidate < distance[neighbor] {
				distance[neighbor], reachable[neighbor] = candidate, true
				if !queued[neighbor] {
					if removed_before[neighbor] {
						front = (front + n - 1) % n
						deque[front] = neighbor
					} else {
						deque[(front + size) % n] = neighbor
					}
					size += 1
					queued[neighbor] = true
				}
			}
		}
	}

	byte_count := 8 * n
	if output == nil || output_capacity < c.size_t(byte_count) do return -2
	for vertex := 0; vertex < n; vertex += 1 {
		result := i64(-1)
		if reachable[vertex] do result = distance[vertex]
		store_i64_le(output, 8 * vertex, result)
	}
	return i64(byte_count)
}
