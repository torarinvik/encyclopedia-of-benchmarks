// Clean-room bounded GARDENIA Gebremedhin-Manne coloring profile.
const max_n = 16
const max_m = 64
const max_input = 130
const max_color = 128

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits >> u64(8 * byte)) } }
}

@[export: 'gardenia_gm_vertex_coloring']
pub fn gardenia_gm_vertex_coloring(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 1 || n64 > max_n || m64 < 0 || m64 > max_m || length != usize(2 + 2 * m64) { return -1 }
		n, m := int(n64), int(m64)
		mut adjacent := [max_n * max_n]u8{}
		for e in 0 .. m {
			u64, v64 := input[2 + 2 * e], input[3 + 2 * e]
			if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1 }
			u, v := int(u64), int(v64)
			if adjacent[u * max_n + v] != 0 { return -1 }
			adjacent[u * max_n + v], adjacent[v * max_n + u] = 1, 1
		}
		output_bytes := usize(8 * n)
		if output == nil || capacity < output_bytes { return -2 }
		mut colors := [max_n]int{}
		mut prior := [max_n]int{}
		mut pending := [max_n]int{}
		mut next_pending := [max_n]int{}
		mut pending_count := n
		for u in 0 .. n { colors[u] = max_color; pending[u] = u }
		mut rounds := 0
		for pending_count > 0 {
			rounds++
			if rounds > n + 1 { return -1 }
			for u in 0 .. n { prior[u] = colors[u] }
			for item in 0 .. pending_count {
				u := pending[item]
				mut forbidden := [max_n]bool{}
				for v in 0 .. n { if adjacent[u * max_n + v] != 0 && prior[v] != max_color { forbidden[prior[v]] = true } }
				mut color := 0
				for color < max_color && forbidden[color] { color++ }
				if color >= max_color { return -1 }
				colors[u] = color
			}
			mut next_count := 0
			for item in 0 .. pending_count {
				u := pending[item]
				mut conflict := false
				for v in u + 1 .. n { if adjacent[u * max_n + v] != 0 && colors[u] == colors[v] { conflict = true; break } }
				if conflict { colors[u] = max_color; next_pending[next_count] = u; next_count++ }
			}
			pending_count = next_count
			for item in 0 .. pending_count { pending[item] = next_pending[item] }
		}
		for u in 0 .. n { put_i64_le(mut output, 8 * u, i64(colors[u])) }
		return i64(output_bytes)
	}
}
