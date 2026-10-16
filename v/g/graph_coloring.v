module graph_coloring

const max_vertices = 8
const max_colors = 4
const max_validation_length = 11
const output_bytes = 8

fn count_from(masks &u8, mut colors &u8, vertex_count int, color_count int, vertex int) i64 {
	if vertex == vertex_count { return 1 }
	mut count := i64(0)
	for color in 0 .. color_count {
		mut safe := true
		for prior in 0 .. vertex {
			if (unsafe { masks[vertex] } & u8(1 << prior)) != 0 && int(unsafe { colors[prior] }) == color {
				safe = false
				break
			}
		}
		if safe {
			unsafe { colors[vertex] = u8(color) }
			count += count_from(masks, mut colors, vertex_count, color_count, vertex + 1)
		}
	}
	return count
}

fn put_i64_le(mut output &u8, value i64) {
	mut bits := u64(value)
	for byte in 0 .. output_bytes {
		unsafe { output[byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'graph_coloring']
pub fn graph_coloring(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > usize(max_validation_length) { return -1 }
	unsafe {
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > i64(max_vertices) || m64 < 1 || m64 > i64(max_colors) { return -1 }
		n := int(n64)
		m := int(m64)
		if length != usize(n + 2) { return -1 }

		mut masks := [max_vertices]u8{}
		mut colors := [max_vertices]u8{}
		for vertex in 0 .. n {
			row := input[2 + vertex]
			if row < 0 || row >= (i64(1) << n) { return -1 }
			masks[vertex] = u8(row)
			if (masks[vertex] & u8(1 << vertex)) != 0 { return -1 }
		}
		for vertex in 0 .. n {
			for neighbor in 0 .. n {
				edge := (masks[vertex] & u8(1 << neighbor)) != 0
				reverse_edge := (masks[neighbor] & u8(1 << vertex)) != 0
				if edge != reverse_edge { return -1 }
			}
		}
		if output == nil || capacity < usize(output_bytes) { return -2 }
		count := count_from(&masks[0], mut colors, n, m, 0)
		put_i64_le(mut output, count)
		return i64(output_bytes)
	}
}
