module single_source_dynamic_reachability_rebuild

import core.c

const max_n = 8
const max_initial_edges = 16
const max_operations = 20
const max_output_bytes = 168

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

fn rebuild_reachable(n int, source int, adjacency [max_n][max_n]bool, mut reachable [max_n]bool) {
	mut queue := [max_n]int{}
	mut head := 0
	mut tail := 0
	for i in 0 .. n { reachable[i] = false }
	reachable[source] = true
	queue[tail] = source
	tail++
	for head < tail {
		u := queue[head]
		head++
		for v in 0 .. n {
			if adjacency[u][v] && !reachable[v] {
				reachable[v] = true
				queue[tail] = v
				tail++
			}
		}
	}
}

@[export: 'single_source_dynamic_reachability_rebuild']
pub fn single_source_dynamic_reachability_rebuild(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 97 { return -1 }
		n_raw := input[0]
		source_raw := input[1]
		edge_count_raw := input[2]
		if n_raw < 2 || n_raw > max_n || source_raw < 0 || source_raw >= n_raw || edge_count_raw < 0 || edge_count_raw > max_initial_edges { return -1 }
		n := int(n_raw)
		source := int(source_raw)
		edge_count := int(edge_count_raw)
		operation_count_offset := 3 + 2 * edge_count
		if length <= usize(operation_count_offset) { return -1 }
		operation_count_raw := input[operation_count_offset]
		if operation_count_raw < 0 || operation_count_raw > max_operations || length != usize(operation_count_offset + 1 + 3 * int(operation_count_raw)) { return -1 }
		operation_count := int(operation_count_raw)

		mut adjacency := [max_n][max_n]bool{}
		mut cursor := 3
		for _ in 0 .. edge_count {
			u_raw := input[cursor]
			v_raw := input[cursor + 1]
			cursor += 2
			if u_raw < 0 || u_raw >= n_raw || v_raw < 0 || v_raw >= n_raw { return -1 }
			u := int(u_raw)
			v := int(v_raw)
			if adjacency[u][v] { return -1 }
			adjacency[u][v] = true
		}
		cursor = operation_count_offset + 1
		mut op_type := [max_operations]int{}
		mut op_u := [max_operations]int{}
		mut op_v := [max_operations]int{}
		mut query_count := 0
		for i in 0 .. operation_count {
			kind := input[cursor]
			u_raw := input[cursor + 1]
			v_raw := input[cursor + 2]
			cursor += 3
			if kind == 0 || kind == 1 {
				if u_raw < 0 || u_raw >= n_raw || v_raw < 0 || v_raw >= n_raw { return -1 }
			} else if kind == 2 {
				if u_raw < 0 || u_raw >= n_raw || v_raw != 0 { return -1 }
				query_count++
			} else { return -1 }
			op_type[i] = int(kind)
			op_u[i] = int(u_raw)
			op_v[i] = int(v_raw)
		}

		output_bytes := 8 * (1 + query_count)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut reachable := [max_n]bool{}
		mut answers := [max_operations]i64{}
		mut answer_count := 0
		rebuild_reachable(n, source, adjacency, mut reachable)
		for i in 0 .. operation_count {
			if op_type[i] == 0 {
				adjacency[op_u[i]][op_v[i]] = true
				rebuild_reachable(n, source, adjacency, mut reachable)
			} else if op_type[i] == 1 {
				adjacency[op_u[i]][op_v[i]] = false
				rebuild_reachable(n, source, adjacency, mut reachable)
			} else {
				answers[answer_count] = if reachable[op_u[i]] { 1 } else { 0 }
				answer_count++
			}
		}
		mut staged := [max_output_bytes]u8{}
		put_i64(mut staged[..], 0, i64(answer_count))
		for i in 0 .. answer_count { put_i64(mut staged[..], 8 * (i + 1), answers[i]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
