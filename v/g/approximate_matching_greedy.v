module approximate_matching_greedy

struct Edge {
	u int
	v int
	weight i64
	mut:
	used bool
}

fn put_i64(mut output &u8, word int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[word * 8 + b] = u8((bits >> u64(8*b)) & 255) } }
}

@[export: 'approximate_matching_greedy']
pub fn approximate_matching_greedy(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 98 { return -1 }
	unsafe {
		n0, m0 := input[0], input[1]
		if n0 < 1 || n0 > 12 || m0 < 0 || m0 > 32 || length != usize(2+3*m0) { return -1 }
		m := int(m0)
		mut seen := []bool{len: 144, init: false}
		mut matched := []bool{len: 12, init: false}
		mut edges := []Edge{len: 32, init: Edge{}}
		for i in 0 .. m {
			u0, v0, weight := input[2+3*i], input[3+3*i], input[4+3*i]
			if u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || weight < 1 || weight > 100 { return -1 }
			u, v := int(u0), int(v0)
			mut lo := u; mut hi := v
			if lo > hi { lo, hi = hi, lo }
			if seen[lo * 12 + hi] { return -1 }
			seen[lo * 12 + hi] = true; edges[i] = Edge{u: u, v: v, weight: weight}
		}
		if output == nil || capacity < 16 { return -2 }
		mut total := i64(0); mut selected := u64(0)
		for _ in 0 .. m {
			mut best := m
			for i in 0 .. m { if !edges[i].used && (best == m || edges[i].weight > edges[best].weight) { best = i } }
			edges[best].used = true; edge := edges[best]
			if !matched[edge.u] && !matched[edge.v] {
				matched[edge.u] = true; matched[edge.v] = true
				selected |= u64(1) << u32(best); total += edge.weight
			}
		}
		put_i64(mut output, 0, total); put_i64(mut output, 1, i64(selected))
		return 16
	}
}
