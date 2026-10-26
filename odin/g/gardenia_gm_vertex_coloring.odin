// Clean-room bounded GARDENIA Gebremedhin-Manne coloring profile.
package gardenia_gm_vertex_coloring

import "core:c"

MAX_N :: 16
MAX_M :: 64
MAX_INPUT :: 130
MAX_COLOR :: 128

put_i64_le :: proc(out: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		out[offset+byte] = u8(bits >> (8*byte))
	}
}

@(export)
gardenia_gm_vertex_coloring :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n64, m64 := input[0], input[1]
	if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || length != c.size_t(2+2*m64) do return -1
	n, m := int(n64), int(m64)
	adjacent: [MAX_N*MAX_N]u8 = {}
	for e := 0; e < m; e += 1 {
		u64, v64 := input[2+2*e], input[3+2*e]
		if u64 < 0 || v64 <= u64 || v64 >= n64 do return -1
		u, v := int(u64), int(v64)
		if adjacent[u*MAX_N+v] != 0 do return -1
		adjacent[u*MAX_N+v], adjacent[v*MAX_N+u] = 1, 1
	}
	output_bytes := c.size_t(8*n)
	if output == nil || capacity < output_bytes do return -2
	colors, prior: [MAX_N]int
	pending, next_pending: [MAX_N]int
	pending_count := n
	for u := 0; u < n; u += 1 { colors[u] = MAX_COLOR; pending[u] = u }
	rounds := 0
	for pending_count > 0 {
		rounds += 1
		if rounds > n+1 do return -1
		for u := 0; u < n; u += 1 do prior[u] = colors[u]
		for item := 0; item < pending_count; item += 1 {
			u := pending[item]
			forbidden: [MAX_N]bool = {}
			for v := 0; v < n; v += 1 {
				if adjacent[u*MAX_N+v] != 0 && prior[v] != MAX_COLOR do forbidden[prior[v]] = true
			}
			color := 0
			for color < MAX_COLOR && forbidden[color] do color += 1
			if color >= MAX_COLOR do return -1
			colors[u] = color
		}
		next_count := 0
		for item := 0; item < pending_count; item += 1 {
			u := pending[item]
			conflict := false
			for v := u+1; v < n; v += 1 {
				if adjacent[u*MAX_N+v] != 0 && colors[u] == colors[v] { conflict = true; break }
			}
			if conflict { colors[u] = MAX_COLOR; next_pending[next_count] = u; next_count += 1 }
		}
		pending_count = next_count
		for item := 0; item < pending_count; item += 1 do pending[item] = next_pending[item]
	}
	for u := 0; u < n; u += 1 do put_i64_le(output, 8*u, i64(colors[u]))
	return i64(output_bytes)
}
