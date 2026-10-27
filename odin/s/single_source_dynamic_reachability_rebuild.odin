package single_source_dynamic_reachability_rebuild

import "core:c"

MAX_N :: 8
MAX_INITIAL_EDGES :: 16
MAX_OPERATIONS :: 20
MAX_OUTPUT_BYTES :: 168

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

rebuild_reachable :: proc(n, source: int, adjacency: ^[MAX_N][MAX_N]bool, reachable: ^[MAX_N]bool) {
	queue: [MAX_N]int = {}
	head, tail := 0, 0
	for i := 0; i < n; i += 1 { reachable[i] = false }
	reachable[source] = true
	queue[tail] = source; tail += 1
	for head < tail {
		u := queue[head]; head += 1
		for v := 0; v < n; v += 1 {
			if adjacency[u][v] && !reachable[v] {
				reachable[v] = true
				queue[tail] = v; tail += 1
			}
		}
	}
}

@(export)
single_source_dynamic_reachability_rebuild :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 97 do return -1
	n_raw, source_raw, edge_count_raw := input[0], input[1], input[2]
	if n_raw < 2 || n_raw > MAX_N || source_raw < 0 || source_raw >= n_raw || edge_count_raw < 0 || edge_count_raw > MAX_INITIAL_EDGES do return -1
	n, source, edge_count := int(n_raw), int(source_raw), int(edge_count_raw)
	operation_count_offset := 3 + 2 * edge_count
	if length <= c.size_t(operation_count_offset) do return -1
	operation_count_raw := input[operation_count_offset]
	if operation_count_raw < 0 || operation_count_raw > MAX_OPERATIONS || length != c.size_t(operation_count_offset+1+3*operation_count_raw) do return -1
	operation_count := int(operation_count_raw)

	adjacency: [MAX_N][MAX_N]bool = {}
	cursor := 3
	for i := 0; i < edge_count; i += 1 {
		u_raw, v_raw := input[cursor], input[cursor+1]; cursor += 2
		if u_raw < 0 || u_raw >= n_raw || v_raw < 0 || v_raw >= n_raw do return -1
		u, v := int(u_raw), int(v_raw)
		if adjacency[u][v] do return -1
		adjacency[u][v] = true
	}
	cursor = operation_count_offset + 1
	op_type, op_u, op_v: [MAX_OPERATIONS]int = {}, {}, {}
	query_count := 0
	for i := 0; i < operation_count; i += 1 {
		kind, u_raw, v_raw := input[cursor], input[cursor+1], input[cursor+2]; cursor += 3
		if kind == 0 || kind == 1 {
			if u_raw < 0 || u_raw >= n_raw || v_raw < 0 || v_raw >= n_raw do return -1
		} else if kind == 2 {
			if u_raw < 0 || u_raw >= n_raw || v_raw != 0 do return -1
			query_count += 1
		} else do return -1
		op_type[i], op_u[i], op_v[i] = int(kind), int(u_raw), int(v_raw)
	}

	output_bytes := 8 * (1 + query_count)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	reachable: [MAX_N]bool = {}
	answers: [MAX_OPERATIONS]i64 = {}
	answer_count := 0
	rebuild_reachable(n, source, &adjacency, &reachable)
	for i := 0; i < operation_count; i += 1 {
		if op_type[i] == 0 {
			adjacency[op_u[i]][op_v[i]] = true
			rebuild_reachable(n, source, &adjacency, &reachable)
		} else if op_type[i] == 1 {
			adjacency[op_u[i]][op_v[i]] = false
			rebuild_reachable(n, source, &adjacency, &reachable)
		} else {
			answers[answer_count] = if reachable[op_u[i]] do 1 else 0
			answer_count += 1
		}
	}
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	store_i64_le(&staged[0], 0, i64(answer_count))
	for i := 0; i < answer_count; i += 1 { store_i64_le(&staged[0], 8*(i+1), answers[i]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
