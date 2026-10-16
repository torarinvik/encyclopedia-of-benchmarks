package graph_rust_weighted

import "core:c"

MAX_VERTICES :: 64
MAX_EDGES :: 256

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> (8 * byte))
	}
}

@(export)
graph_rust_weighted :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	nv, mv := input[0], input[1]
	if nv < 0 || nv > MAX_VERTICES || mv < 0 || mv > MAX_EDGES || length != c.size_t(2 + 3 * mv) do return -1
	n, m := int(nv), int(mv)
	for edge := 0; edge < m; edge += 1 {
		u, v, weight := input[2 + 3 * edge], input[3 + 3 * edge], input[4 + 3 * edge]
		if u < 0 || u >= nv || v < 0 || v >= nv || weight < -2147483648 || weight > 2147483647 do return -1
	}
	required := (1 + n + 4 * m) * 8
	if output == nil || capacity < c.size_t(required) do return -2
	cursor := 0
	put_i64(output, cursor * 8, nv)
	cursor += 1
	for vertex := 0; vertex < n; vertex += 1 {
		degree := 0
		for edge := 0; edge < m; edge += 1 {
			if input[2 + 3 * edge] == i64(vertex) do degree += 1
			if input[3 + 3 * edge] == i64(vertex) do degree += 1
		}
		put_i64(output, cursor * 8, i64(degree))
		cursor += 1
		for edge := 0; edge < m; edge += 1 {
			u, v, weight := input[2 + 3 * edge], input[3 + 3 * edge], input[4 + 3 * edge]
			if u == i64(vertex) {
				put_i64(output, cursor * 8, v)
				cursor += 1
				put_i64(output, cursor * 8, weight)
				cursor += 1
			}
			if v == i64(vertex) {
				put_i64(output, cursor * 8, u)
				cursor += 1
				put_i64(output, cursor * 8, weight)
				cursor += 1
			}
		}
	}
	return i64(required)
}
