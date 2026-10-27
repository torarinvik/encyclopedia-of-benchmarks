package max_cut_gw_rounding

import "core:c"

MAX_N :: 16
MAX_M :: 120
MAX_D :: 4
MAX_INPUT :: 431

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
max_cut_gw_rounding :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n64, m64, d64 := input[0], input[1], input[2]
	if n64 < 2 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || d64 < 1 || d64 > MAX_D ||
		length != c.size_t(3+3*m64+n64*d64+d64) do return -1
	n, m, d := int(n64), int(m64), int(d64)
	edge_u, edge_v, edge_weight: [MAX_M]i64
	previous_u, previous_v := i64(-1), i64(-1)
	for edge := 0; edge < m; edge += 1 {
		u, v, weight := input[3+3*edge], input[4+3*edge], input[5+3*edge]
		if u < 0 || v <= u || v >= n64 || weight < 1 || weight > 10000 ||
			u < previous_u || (u == previous_u && v <= previous_v) do return -1
		previous_u, previous_v = u, v
		edge_u[edge], edge_v[edge], edge_weight[edge] = u, v, weight
	}
	vector_offset := 3+3*m
	vectors: [MAX_N][MAX_D]i64
	normal: [MAX_D]i64
	common_norm := i64(0)
	for vertex := 0; vertex < n; vertex += 1 {
		norm := i64(0)
		for axis := 0; axis < d; axis += 1 {
			coordinate := input[vector_offset+vertex*d+axis]
			if coordinate < -100 || coordinate > 100 do return -1
			vectors[vertex][axis] = coordinate
			norm += coordinate*coordinate
		}
		if vertex == 0 { common_norm = norm } else if norm != common_norm do return -1
	}
	if common_norm == 0 do return -1
	has_normal := false
	for axis := 0; axis < d; axis += 1 {
		normal[axis] = input[vector_offset+n*d+axis]
		if normal[axis] < -100 || normal[axis] > 100 do return -1
		if normal[axis] != 0 do has_normal = true
	}
	if !has_normal do return -1
	output_bytes := 8*(n+1)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	side: [MAX_N]i64
	for vertex := 0; vertex < n; vertex += 1 {
		projection := i64(0)
		for axis := 0; axis < d; axis += 1 { projection += vectors[vertex][axis]*normal[axis] }
		if projection > 0 do side[vertex] = 1
	}
	cut := i64(0)
	for edge := 0; edge < m; edge += 1 {
		if side[int(edge_u[edge])] != side[int(edge_v[edge])] do cut += edge_weight[edge]
	}
	store_i64_le(output, 0, cut)
	for vertex := 0; vertex < n; vertex += 1 do store_i64_le(output, 8*(vertex+1), side[vertex])
	return i64(output_bytes)
}
