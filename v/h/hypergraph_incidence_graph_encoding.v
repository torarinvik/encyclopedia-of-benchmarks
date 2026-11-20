module hypergraph_incidence_graph_encoding
import core.c

const max_n = 8
const max_m = 12
const max_input = 111

fn put_le(output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'hypergraph_incidence_graph_encoding']
pub fn hypergraph_incidence_graph_encoding(input &i64, length usize,
	output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n64, m64 := input[0], input[1]
		if n64 < 1 || n64 > 8 || m64 < 0 || m64 > 12 { return -1 }
		n, m := int(n64), int(m64)
		mut incidence := []bool{len: max_n * max_m, init: false}
		mut offset := 2
		for edge in 0 .. m {
			if usize(offset) >= length { return -1 }
			size64 := input[offset]
			offset++
			if size64 < 0 || size64 > n64 || usize(size64) > length - usize(offset) { return -1 }
			for _ in 0 .. int(size64) {
				vertex64 := input[offset]
				offset++
				if vertex64 < 0 || vertex64 >= n64 { return -1 }
				vertex := int(vertex64)
				if incidence[vertex * max_m + edge] { return -1 }
				incidence[vertex * max_m + edge] = true
			}
		}
		if usize(offset) != length { return -1 }

		mut count := 0
		for vertex in 0 .. n {
			for edge in 0 .. m { if incidence[vertex * max_m + edge] { count++ } }
		}
		nodes := n + m
		bytes := 8 * (2 + nodes + 2 * count)
		if output == nil || capacity < usize(bytes) { return -2 }
		put_le(output, 0, i64(nodes))
		put_le(output, 8, i64(count))
		mut word := 2
		for _ in 0 .. n { put_le(output, 8 * word, 0); word++ }
		for _ in 0 .. m { put_le(output, 8 * word, 1); word++ }
		for vertex in 0 .. n {
			for edge in 0 .. m {
				if incidence[vertex * max_m + edge] {
					put_le(output, 8 * word, i64(vertex)); word++
					put_le(output, 8 * word, i64(n + edge)); word++
				}
			}
		}
		return i64(bytes)
	}
}
