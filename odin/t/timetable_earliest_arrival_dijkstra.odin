package timetable_earliest_arrival_dijkstra

import "core:c"

MAX_N :: 8
MAX_ARCS :: 12
MAX_TRIPS :: 4
MAX_OUTPUT_BYTES :: 88
INF :: i64(1_000_000_000)

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
timetable_earliest_arrival_dijkstra :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 138 do return -1
	n_raw, arc_count_raw, source_raw, target_raw, start_time := input[0], input[1], input[2], input[3], input[4]
	if n_raw < 2 || n_raw > MAX_N || arc_count_raw < 0 || arc_count_raw > MAX_ARCS || source_raw < 0 || source_raw >= n_raw || target_raw < 0 || target_raw >= n_raw || start_time < 0 || start_time > 1000 do return -1
	n, arc_count, source, target := int(n_raw), int(arc_count_raw), int(source_raw), int(target_raw)
	arc_u, arc_v, trip_count: [MAX_ARCS]int = {}, {}, {}
	departure, arrival: [MAX_ARCS][MAX_TRIPS]i64 = {}, {}
	cursor := 5
	for edge := 0; edge < arc_count; edge += 1 {
		if cursor+3 > int(length) do return -1
		u_raw, v_raw, count_raw := input[cursor], input[cursor+1], input[cursor+2]; cursor += 3
		if u_raw < 0 || u_raw >= n_raw || v_raw < 0 || v_raw >= n_raw || u_raw == v_raw || count_raw < 1 || count_raw > MAX_TRIPS || cursor+2*int(count_raw) > int(length) do return -1
		u, v, count := int(u_raw), int(v_raw), int(count_raw)
		for prior := 0; prior < edge; prior += 1 { if arc_u[prior] == u && arc_v[prior] == v do return -1 }
		arc_u[edge], arc_v[edge], trip_count[edge] = u, v, count
		for trip := 0; trip < count; trip += 1 {
			dep, arr := input[cursor], input[cursor+1]; cursor += 2
			if dep < 0 || dep > 1000 || arr <= dep || arr > 2000 || (trip > 0 && (dep <= departure[edge][trip-1] || arr < arrival[edge][trip-1])) do return -1
			departure[edge][trip], arrival[edge][trip] = dep, arr
		}
	}
	if cursor != int(length) do return -1

	distance: [MAX_N]i64 = {}
	parent: [MAX_N]int = {}
	settled: [MAX_N]bool = {}
	for vertex := 0; vertex < n; vertex += 1 { distance[vertex] = INF; parent[vertex] = -1 }
	distance[source] = start_time
	for _ := 0; _ < n; _ += 1 {
		chosen := -1
		for vertex := 0; vertex < n; vertex += 1 {
			if !settled[vertex] && distance[vertex] < INF && (chosen < 0 || distance[vertex] < distance[chosen] || (distance[vertex] == distance[chosen] && vertex < chosen)) do chosen = vertex
		}
		if chosen < 0 do break
		settled[chosen] = true
		for edge := 0; edge < arc_count; edge += 1 {
			v := arc_v[edge]
			if arc_u[edge] != chosen || settled[v] do continue
			trip := 0
			for trip < trip_count[edge] && departure[edge][trip] < distance[chosen] { trip += 1 }
			if trip == trip_count[edge] do continue
			candidate := arrival[edge][trip]
			if candidate < distance[v] || (candidate == distance[v] && (parent[v] < 0 || chosen < parent[v])) { distance[v] = candidate; parent[v] = chosen }
		}
	}

	reverse_path: [MAX_N]int = {}
	path_length := 0
	if distance[target] < INF {
		current := target
		reverse_path[path_length] = current; path_length += 1
		for current != source && path_length < n {
			if parent[current] < 0 { path_length = 0; break }
			current = parent[current]
			reverse_path[path_length] = current; path_length += 1
		}
		if path_length == 0 || reverse_path[path_length-1] != source do path_length = 0
	}
	reachable := path_length > 0
	output_bytes := if reachable { 8*(3+path_length) } else { 24 }
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	store_i64_le(&staged[0], 0, if reachable { 1 } else { 0 })
	store_i64_le(&staged[0], 8, if reachable { distance[target] } else { -1 })
	store_i64_le(&staged[0], 16, i64(path_length))
	if reachable { for i := 0; i < path_length; i += 1 { store_i64_le(&staged[0], 24+8*i, i64(reverse_path[path_length-1-i])) } }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
