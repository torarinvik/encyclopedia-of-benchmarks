// Clean-room bounded GARDENIA Forward-Backward-Trim SCC profile.
package gardenia_fb_trim_scc

import "core:c"

MAX_N :: 16
MAX_M :: 64
MAX_INPUT :: 130
MAX_TASKS :: 34

put_i64_le :: proc(out: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		out[offset+byte] = u8(bits >> (8*byte))
	}
}

reach :: proc(active: u32, pivot: int, adjacency: [^]u8, reverse: bool, n: int) -> u32 {
	seen := u32(1) << pivot
	for {
		expanded := seen
		for u := 0; u < n; u += 1 {
			ub := u32(1) << u
			if seen & ub == 0 || active & ub == 0 do continue
			for v := 0; v < n; v += 1 {
				vb := u32(1) << v
				edge := adjacency[u*MAX_N+v] != 0
				if reverse do edge = adjacency[v*MAX_N+u] != 0
				if active & vb != 0 && edge do expanded |= vb
			}
		}
		if expanded == seen do return seen
		seen = expanded
	}
}

@(export)
gardenia_fb_trim_scc :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n64, m64 := input[0], input[1]
	if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || length != c.size_t(2+2*m64) do return -1
	n, m := int(n64), int(m64)
	adjacency: [MAX_N*MAX_N]u8 = {}
	for e := 0; e < m; e += 1 {
		u64, v64 := input[2+2*e], input[3+2*e]
		if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 do return -1
		u, v := int(u64), int(v64)
		if adjacency[u*MAX_N+v] != 0 do return -1
		adjacency[u*MAX_N+v] = 1
	}
	output_bytes := c.size_t(8*n)
	if output == nil || capacity < output_bytes do return -2
	labels: [MAX_N]i64 = {}
	tasks: [MAX_TASKS]u32 = {}
	task_count := 1
	tasks[0] = (u32(1) << n)-1
	for task_count > 0 {
		task_count -= 1
		active := tasks[task_count]
		for active != 0 {
			trimmed: u32 = 0
			for u := 0; u < n; u += 1 {
				ub := u32(1) << u
				if active & ub == 0 do continue
				has_in, has_out := false, false
				for v := 0; v < n; v += 1 {
					if active & (u32(1)<<v) == 0 do continue
					has_out = has_out || adjacency[u*MAX_N+v] != 0
					has_in = has_in || adjacency[v*MAX_N+u] != 0
				}
				if !has_in || !has_out do trimmed |= ub
			}
			if trimmed == 0 do break
			for u := 0; u < n; u += 1 do if trimmed & (u32(1)<<u) != 0 { labels[u] = i64(u) }
			active &= ~trimmed
		}
		if active == 0 do continue
		pivot := 0
		for active & (u32(1)<<pivot) == 0 do pivot += 1
		forward := reach(active, pivot, &adjacency[0], false, n)
		backward := reach(active, pivot, &adjacency[0], true, n)
		component := forward & backward
		representative := 0
		for component & (u32(1)<<representative) == 0 do representative += 1
		for u := 0; u < n; u += 1 do if component & (u32(1)<<u) != 0 { labels[u] = i64(representative) }
		children := [3]u32{active & ~(forward|backward), forward & ~backward, backward & ~forward}
		for child in children {
			if child != 0 {
				if task_count >= MAX_TASKS do return -1
				tasks[task_count] = child
				task_count += 1
			}
		}
	}
	for u := 0; u < n; u += 1 do put_i64_le(output, 8*u, labels[u])
	return i64(output_bytes)
}
