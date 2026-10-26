// Clean-room exact branch-and-search vertex-cover profile.
module vertex_cover_search_trees

const max_n = 16
const max_input = 131

fn bit_count(mut value u64) int {
	mut count := 0
	for value != 0 { count += int(value & 1); value >>= 1 }
	return count
}

fn search_cover(adj [max_n][max_n]bool, n int, active u64) u64 {
	mut chosen := n
	mut best_degree := 0
	mut any_edge := false
	for u in 0 .. n {
		if active & (u64(1) << u32(u)) == 0 { continue }
		mut degree := 0
		for v in 0 .. n { if active & (u64(1) << u32(v)) != 0 && adj[u][v] { degree++ } }
		if degree > 0 { any_edge = true; if chosen == n || degree > best_degree { chosen = u; best_degree = degree } }
	}
	if !any_edge { return 0 }
	bit := u64(1) << u32(chosen)
	first := bit | search_cover(adj, n, active & ~bit)
	mut neighbors := u64(0)
	for v in 0 .. n { if active & (u64(1) << u32(v)) != 0 && adj[chosen][v] { neighbors |= u64(1) << u32(v) } }
	second := neighbors | search_cover(adj, n, active & ~(neighbors | bit))
	a := bit_count(first); b := bit_count(second)
	if a < b { return first }
	if b < a { return second }
	return if first < second { first } else { second }
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for i in 0 .. 8 { unsafe { output[offset+i] = u8((bits >> (8*i)) & 255) } }
}

@[export: 'vertex_cover_search_trees']
pub fn vertex_cover_search_trees(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n64, m64, k := input[0], input[1], input[2]
		if n64 < 1 || n64 > max_n || m64 < 0 || m64 > 64 || k < 0 || k > n64 || length != usize(3+2*m64) { return -1 }
		n, m := int(n64), int(m64)
		mut adj := [max_n][max_n]bool{}
		mut pu, mut pv := i64(-1), i64(-1)
		for e in 0 .. m {
			u, v := input[3+2*e], input[4+2*e]
			if u < 0 || v <= u || v >= n64 || u < pu || (u == pu && v <= pv) { return -1 }
			adj[int(u)][int(v)] = true; adj[int(v)][int(u)] = true; pu = u; pv = v
		}
		if output == nil || capacity < 24 { return -2 }
		cover := search_cover(adj, n, (u64(1) << u32(n)) - 1)
		count := bit_count(cover)
		put_i64_le(mut output, 0, if i64(count) <= k { 1 } else { 0 })
		put_i64_le(mut output, 8, i64(count))
		put_i64_le(mut output, 16, i64(cover))
		return 24
	}
}
