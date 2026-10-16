module graph_rust_weighted

import core:c

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'graph_rust_weighted']
pub fn graph_rust_weighted(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		nv, mv := input[0], input[1]
		if nv < 0 || nv > 64 || mv < 0 || mv > 256 || length != usize(2 + 3 * mv) { return -1 }
		n, m := int(nv), int(mv)
		for edge in 0 .. m {
			u, v, weight := input[2 + 3 * edge], input[3 + 3 * edge], input[4 + 3 * edge]
			if u < 0 || u >= nv || v < 0 || v >= nv || weight < -2147483648 || weight > 2147483647 { return -1 }
		}
		required := (1 + n + 4 * m) * 8
		if capacity < required || (required != 0 && output == nil) { return -2 }
		mut cursor := 0
		put_i64(mut output, cursor * 8, nv)
		cursor++
		for vertex in 0 .. n {
			mut degree := 0
			for edge in 0 .. m {
				if input[2 + 3 * edge] == i64(vertex) { degree++ }
				if input[3 + 3 * edge] == i64(vertex) { degree++ }
			}
			put_i64(mut output, cursor * 8, i64(degree))
			cursor++
			for edge in 0 .. m {
				u, v, weight := input[2 + 3 * edge], input[3 + 3 * edge], input[4 + 3 * edge]
				if u == i64(vertex) {
					put_i64(mut output, cursor * 8, v)
					cursor++
					put_i64(mut output, cursor * 8, weight)
					cursor++
				}
				if v == i64(vertex) {
					put_i64(mut output, cursor * 8, u)
					cursor++
					put_i64(mut output, cursor * 8, weight)
					cursor++
				}
			}
		}
		return i64(required)
	}
}
