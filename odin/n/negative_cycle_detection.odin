// Clean-room negative-cycle detection and witness extraction.
package negative_cycle_detection

import "core:c"

MAX_N :: 20
MAX_M :: 64
MAX_INPUT :: 2 + 3 * MAX_M

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
negative_cycle_detection :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n64, m64 := input[0], input[1]
	if n64 < 0 || n64 > MAX_N || m64 < 0 || m64 > MAX_M do return -1
	n, m := int(n64), int(m64)
	if length != c.size_t(2 + 3*m) do return -1
	edge_from, edge_to: [MAX_M]int = {}, {}
	weight: [MAX_M]i64 = {}
	for edge := 0; edge < m; edge += 1 {
		u64, v64, w := input[2+3*edge], input[3+3*edge], input[4+3*edge]
		if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || w < -1000 || w > 1000 do return -1
		edge_from[edge], edge_to[edge], weight[edge] = int(u64), int(v64), w
	}
	distance: [MAX_N]i64 = {}
	predecessor: [MAX_N]int = {}
	for v := 0; v < n; v += 1 do predecessor[v] = -1
	changed_vertex := -1
	for _pass := 0; _pass < n; _pass += 1 {
		changed_vertex = -1
		for edge := 0; edge < m; edge += 1 {
			u, v := edge_from[edge], edge_to[edge]
			candidate := distance[u] + weight[edge]
			if candidate < distance[v] { distance[v] = candidate; predecessor[v] = u; changed_vertex = v }
		}
		if changed_vertex < 0 do break
	}
	var record: [MAX_N+2]i64
	record_length := 1
	if changed_vertex >= 0 {
		mut vertex := changed_vertex
		for _step := 0; _step < n; _step += 1 {
			if predecessor[vertex] < 0 do return -1
			vertex = predecessor[vertex]
		}
		start := vertex
		mut cycle: [MAX_N]int
		mut cycle_length := 0
		for {
			if cycle_length >= n || predecessor[vertex] < 0 do return -1
			cycle[cycle_length] = vertex; cycle_length += 1
			vertex = predecessor[vertex]
			if vertex == start do break
		}
		for left := 0; left < cycle_length/2; left += 1 {
			right := cycle_length-1-left
			temporary := cycle[left]; cycle[left] = cycle[right]; cycle[right] = temporary
		}
		mut minimum := 0
		for i := 1; i < cycle_length; i += 1 { if cycle[i] < cycle[minimum] do minimum = i }
		record[0], record[1] = 1, i64(cycle_length)
		for i := 0; i < cycle_length; i += 1 do record[2+i] = i64(cycle[(minimum+i)%cycle_length])
		record_length = cycle_length + 2
	} else { record[0] = 0 }
	output_length := 8 * record_length
	if output == nil || capacity < c.size_t(output_length) do return -2
	for i := 0; i < record_length; i += 1 do store_i64_le(output, 8*i, record[i])
	return i64(output_length)
}
