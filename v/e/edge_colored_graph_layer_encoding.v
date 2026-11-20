module edge_colored_graph_layer_encoding
import core.c

const max_n = 8
const max_m = 28
const max_input = 97
const max_vertices = 24

fn put_le(output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'edge_colored_graph_layer_encoding']
pub fn edge_colored_graph_layer_encoding(input &i64, length usize,
	output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_input { return -1 }
		n0, m0, d0, q0 := input[0], input[1], input[2], input[3]
		if n0 < 1 || n0 > 8 || m0 < 0 || m0 > 28 || d0 < 1 || d0 > 3 || q0 < 1 || q0 > 3 { return -1 }
		n, m, layers, classes := int(n0), int(m0), int(d0), int(q0)
		edge_offset := 4 + n
		if int(length) != edge_offset + 3*m { return -1 }
		mut vertex_colors := []i64{len: max_n, init: 0}
		for vertex in 0 .. n {
			vertex_colors[vertex] = input[4 + vertex]
			if vertex_colors[vertex] < 0 || vertex_colors[vertex] >= q0 { return -1 }
		}
		mut source_edges := []u8{len: max_n * max_n, init: 0}
		offset := edge_offset
		for _ in 0 .. m {
			u0, v0, color0 := input[offset], input[offset + 1], input[offset + 2]
			offset += 3
			if u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || color0 < 1 || color0 >= (1 << d0) { return -1 }
			u, v := int(u0), int(v0)
			if u > v { u, v = v, u }
			if source_edges[u * max_n + v] != 0 { return -1 }
			source_edges[u * max_n + v] = u8(color0)
		}
		nodes := n * layers
		mut adjacency := []bool{len: max_vertices * max_vertices, init: false}
		for layer in 0 .. layers {
			bit := u8(1 << layer)
			for u in 0 .. n {
				for v in u + 1 .. n {
					if (source_edges[u * max_n + v] & bit) != 0 { adjacency[(layer * n + u) * max_vertices + layer * n + v] = true }
				}
			}
		}
		for vertex in 0 .. n {
			for layer in 0 .. layers - 1 {
				adjacency[(layer * n + vertex) * max_vertices + (layer + 1) * n + vertex] = true
			}
		}
		mut edge_count := 0
		for u in 0 .. nodes {
			for v in u + 1 .. nodes {
				if adjacency[u * max_vertices + v] { edge_count++ }
			}
		}
		bytes := 8 * (2 + nodes + 2*edge_count)
		if output == nil || capacity < usize(bytes) { return -2 }
		put_le(output, 0, i64(nodes))
		put_le(output, 8, i64(edge_count))
		mut word := 2
		for layer in 0 .. layers {
			for vertex in 0 .. n {
				put_le(output, 8*word, i64(layer*classes)+vertex_colors[vertex])
				word++
			}
		}
		for u in 0 .. nodes {
			for v in u + 1 .. nodes {
				if adjacency[u * max_vertices + v] {
					put_le(output, 8*word, i64(u)); word++
					put_le(output, 8*word, i64(v)); word++
				}
			}
		}
		return i64(bytes)
	}
}
