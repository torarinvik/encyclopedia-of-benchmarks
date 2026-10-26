// Clean-room exact dyadic CoSimRank profile; see package LICENSE.txt.
@[export: 'gbbs_cosimrank_pair_similarity']
pub fn gbbs_cosimrank_pair_similarity(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > 53 { return -1 }
		n64 := input[0]; m64 := input[1]; source_u64 := input[2]; source_v64 := input[3]; iterations64 := input[4]
		if n64 < 1 || n64 > 8 || m64 < 0 || m64 > 24 || source_u64 < 0 || source_u64 >= n64 ||
			source_v64 < 0 || source_v64 >= n64 || iterations64 < 1 || iterations64 > 4 || length != usize(5+2*m64) { return -1 }
		n := int(n64); m := int(m64)
		mut from := []int{len: 24, init: 0}; mut to := []int{len: 24, init: 0}
		mut degree := []int{len: 8, init: 0}; mut seen := []bool{len: 64, init: false}
		for edge in 0 .. m {
			u64 := input[5+2*edge]; v64 := input[6+2*edge]
			if u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 == v64 { return -1 }
			u := int(u64); v := int(v64)
			if seen[u*8+v] { return -1 }
			seen[u*8+v] = true; from[edge] = u; to[edge] = v; degree[u]++
		}
		for vertex in 0 .. n { if degree[vertex] != 0 && degree[vertex] != 1 && degree[vertex] != 2 && degree[vertex] != 4 { return -1 } }
		if output == nil || capacity < 8 { return -2 }
		mut current_u := []u32{len: 8, init: 0}; mut current_v := []u32{len: 8, init: 0}
		mut next_u := []u32{len: 8, init: 0}; mut next_v := []u32{len: 8, init: 0}
		current_u[int(source_u64)] = 256; current_v[int(source_v64)] = 256
		mut numerator := u32(0)
		if source_u64 == source_v64 { numerator = u32(1) << 20 }
		for step in 0 .. int(iterations64) {
			for edge in 0 .. m {
				u := from[edge]; v := to[edge]
				next_u[v] += current_u[u] / u32(degree[u]); next_v[v] += current_v[u] / u32(degree[u])
			}
			mut dot := u32(0)
			for vertex in 0 .. n { dot += next_u[vertex] * next_v[vertex] }
			numerator += dot << u32(3-step)
			for vertex in 0 .. n { current_u[vertex] = next_u[vertex]; current_v[vertex] = next_v[vertex]; next_u[vertex] = 0; next_v[vertex] = 0 }
		}
		mut bits := u64(0)
		if numerator != 0 {
			mut high := 0; mut probe := numerator
			for probe > 1 { probe >>= 1; high++ }
			exponent := u64(1003+high); significand := u64(numerator) << u64(52-high)
			bits = (exponent << 52) | (significand & ((u64(1) << 52)-1))
		}
		for byte in 0 .. 8 { output[byte] = u8(bits & 255); bits >>= 8 }
		return 8
	}
}
