package max_cut_sahni_gonzalez

import "core:c"

MAX_N :: 16
MAX_M :: 120
MAX_INPUT :: 362

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
max_cut_sahni_gonzalez :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n64, m64 := input[0], input[1]
	if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
		length != c.size_t(2+3*m64) do return -1
	n, m := int(n64), int(m64)
	weights: [MAX_N][MAX_N]i64
	seen: [MAX_N][MAX_N]bool
	for edge := 0; edge < m; edge += 1 {
		u64, v64, weight := input[2+3*edge], input[3+3*edge], input[4+3*edge]
		if u64 < 0 || v64 <= u64 || v64 >= n64 || weight < 0 || weight > 10000 do return -1
		u, v := int(u64), int(v64)
		if seen[u][v] do return -1
		seen[u][v] = true
		weights[u][v], weights[v][u] = weight, weight
	}
	output_bytes := 8*(n+1)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	side: [MAX_N]i64
	for vertex := 0; vertex < n; vertex += 1 {
		put_zero, put_one := i64(0), i64(0)
		for prior := 0; prior < vertex; prior += 1 {
			if side[prior] == 1 { put_zero += weights[prior][vertex] } else { put_one += weights[prior][vertex] }
		}
		if put_one > put_zero do side[vertex] = 1
	}
	cut := i64(0)
	for u := 0; u < n; u += 1 {
		for v := u+1; v < n; v += 1 {
			if side[u] != side[v] do cut += weights[u][v]
		}
	}
	store_i64_le(output, 0, cut)
	for vertex := 0; vertex < n; vertex += 1 do store_i64_le(output, 8*(vertex+1), side[vertex])
	return i64(output_bytes)
}
