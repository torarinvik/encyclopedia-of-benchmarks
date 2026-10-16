fn assign_colors(input &i64, count int, max_colors int, vertex int, mut colors []i64) bool {
	if vertex == count { return true }
	for color in 0 .. max_colors {
		mut safe := true
		for neighbor in 0 .. count {
			if unsafe { input[2 + vertex * count + neighbor] } == 1 && colors[neighbor] == i64(color) {
				safe = false
				break
			}
		}
		if !safe { continue }
		colors[vertex] = i64(color)
		if assign_colors(input, count, max_colors, vertex + 1, mut colors) { return true }
		colors[vertex] = -1
	}
	return false
}

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'graph_m_coloring_backtracking']
pub fn graph_m_coloring_backtracking(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 2 || isnil(input) { return -1 }
	n_value := unsafe { input[0] }
	max_colors_value := unsafe { input[1] }
	if n_value < 0 || n_value > 12 || max_colors_value < 0 || max_colors_value > 12 { return -1 }
	n := int(n_value)
	max_colors := int(max_colors_value)
	if length != usize(2 + n * n) { return -1 }
	for row in 0 .. n {
		if unsafe { input[2 + row * n + row] } != 0 { return -1 }
		for column in 0 .. n {
			cell := unsafe { input[2 + row * n + column] }
			if (cell != 0 && cell != 1) || cell != unsafe { input[2 + column * n + row] } { return -1 }
		}
	}
	mut colors := []i64{len: 12, init: -1}
	if !assign_colors(input, n, max_colors, 0, mut colors) { return 0 }
	required := n * 8
	if required == 0 { return 0 }
	if capacity < required || isnil(output) { return -2 }
	for vertex in 0 .. n { put_i64(mut output, vertex * 8, colors[vertex]) }
	return i64(required)
}
