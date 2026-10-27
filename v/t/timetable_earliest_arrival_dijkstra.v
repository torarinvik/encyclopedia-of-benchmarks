module timetable_earliest_arrival_dijkstra

import core.c

const max_n = 8
const max_arcs = 12
const max_trips = 4
const max_output_bytes = 88
const inf = i64(1_000_000_000)

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'timetable_earliest_arrival_dijkstra']
pub fn timetable_earliest_arrival_dijkstra(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > 138 { return -1 }
		n_raw := input[0]
		arc_count_raw := input[1]
		source_raw := input[2]
		target_raw := input[3]
		start_time := input[4]
		if n_raw < 2 || n_raw > max_n || arc_count_raw < 0 || arc_count_raw > max_arcs || source_raw < 0 || source_raw >= n_raw || target_raw < 0 || target_raw >= n_raw || start_time < 0 || start_time > 1000 { return -1 }
		n := int(n_raw)
		arc_count := int(arc_count_raw)
		source := int(source_raw)
		target := int(target_raw)
		mut arc_u := [max_arcs]int{}
		mut arc_v := [max_arcs]int{}
		mut trip_count := [max_arcs]int{}
		mut departure := [max_arcs][max_trips]i64{}
		mut arrival := [max_arcs][max_trips]i64{}
		mut cursor := 5
		for edge in 0 .. arc_count {
			if cursor + 3 > int(length) { return -1 }
			u_raw := input[cursor]
			v_raw := input[cursor + 1]
			count_raw := input[cursor + 2]
			cursor += 3
			if u_raw < 0 || u_raw >= n_raw || v_raw < 0 || v_raw >= n_raw || u_raw == v_raw || count_raw < 1 || count_raw > max_trips || cursor + 2 * int(count_raw) > int(length) { return -1 }
			u := int(u_raw)
			v := int(v_raw)
			count := int(count_raw)
			for prior in 0 .. edge { if arc_u[prior] == u && arc_v[prior] == v { return -1 } }
			arc_u[edge] = u
			arc_v[edge] = v
			trip_count[edge] = count
			for trip in 0 .. count {
				dep := input[cursor]
				arr := input[cursor + 1]
				cursor += 2
				if dep < 0 || dep > 1000 || arr <= dep || arr > 2000 || (trip > 0 && (dep <= departure[edge][trip - 1] || arr < arrival[edge][trip - 1])) { return -1 }
				departure[edge][trip] = dep
				arrival[edge][trip] = arr
			}
		}
		if cursor != int(length) { return -1 }

		mut distance := [max_n]i64{}
		mut parent := [max_n]int{}
		mut settled := [max_n]bool{}
		for vertex in 0 .. n { distance[vertex] = inf; parent[vertex] = -1 }
		distance[source] = start_time
		for _ in 0 .. n {
			mut chosen := -1
			for vertex in 0 .. n {
				if !settled[vertex] && distance[vertex] < inf && (chosen < 0 || distance[vertex] < distance[chosen] || (distance[vertex] == distance[chosen] && vertex < chosen)) { chosen = vertex }
			}
			if chosen < 0 { break }
			settled[chosen] = true
			for edge in 0 .. arc_count {
				v := arc_v[edge]
				if arc_u[edge] != chosen || settled[v] { continue }
				mut trip := 0
				for trip < trip_count[edge] && departure[edge][trip] < distance[chosen] { trip++ }
				if trip == trip_count[edge] { continue }
				candidate := arrival[edge][trip]
				if candidate < distance[v] || (candidate == distance[v] && (parent[v] < 0 || chosen < parent[v])) { distance[v] = candidate; parent[v] = chosen }
			}
		}

		mut reverse_path := [max_n]int{}
		mut path_length := 0
		if distance[target] < inf {
			mut current := target
			reverse_path[path_length] = current
			path_length++
			for current != source && path_length < n {
				if parent[current] < 0 { path_length = 0; break }
				current = parent[current]
				reverse_path[path_length] = current
				path_length++
			}
			if path_length == 0 || reverse_path[path_length - 1] != source { path_length = 0 }
		}
		reachable := path_length > 0
		output_bytes := if reachable { 8 * (3 + path_length) } else { 24 }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{}
		put_i64(mut staged[..], 0, if reachable { 1 } else { 0 })
		put_i64(mut staged[..], 8, if reachable { distance[target] } else { -1 })
		put_i64(mut staged[..], 16, i64(path_length))
		if reachable { for i in 0 .. path_length { put_i64(mut staged[..], 24 + 8 * i, i64(reverse_path[path_length - 1 - i])) } }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
