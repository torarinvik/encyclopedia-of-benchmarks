// Clean-room high-/low-degree vertex-cover reduction profile.
module vertex_cover_kernelization

const max_n = 16
const max_m = 64
const max_input = 131
const max_fields = 133

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8((bits >> (8*b)) & 255) } }
}

@[export: 'vertex_cover_kernelization']
pub fn vertex_cover_kernelization(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n64, m64, mut k := input[0], input[1], input[2]
		if n64 < 1 || n64 > max_n || m64 < 0 || m64 > max_m || k < 0 || k > max_n || length != usize(3+2*m64) { return -1 }
		n, m := int(n64), int(m64)
		mut edge := [max_n][max_n]bool{}
		mut previous_u, mut previous_v := i64(-1), i64(-1)
		for e in 0 .. m {
			u, v := input[3+2*e], input[4+2*e]
			if u < 0 || v <= u || v >= n64 || u < previous_u || (u == previous_u && v <= previous_v) { return -1 }
			edge[int(u)][int(v)] = true; edge[int(v)][int(u)] = true
			previous_u = u; previous_v = v
		}
		if output == nil { return -2 }
		mut active := [max_n]bool{}
		for i in 0 .. n { active[i] = true }
		mut forced := u64(0)
		mut infeasible := false
		for {
			if k < 0 { infeasible = true; break }
			mut chosen, mut neighbor, mut kind := n, n, 0
			for u in 0 .. n { if active[u] { mut degree := 0; for v in 0 .. n { if edge[u][v] { degree++ } }; if degree == 0 { chosen = u; kind = 1; break } } }
			if kind == 1 { active[chosen] = false; continue }
			for u in 0 .. n { if active[u] { mut degree, mut only := 0, n; for v in 0 .. n { if edge[u][v] { degree++; only = v } }; if degree == 1 { chosen = u; neighbor = only; kind = 2; break } } }
			if kind == 0 { for u in 0 .. n { if active[u] { mut degree := 0; for v in 0 .. n { if edge[u][v] { degree++ } }; if i64(degree) > k { chosen = u; kind = 3; break } } } }
			if kind == 0 { break }
			f := if kind == 2 { neighbor } else { chosen }
			forced |= u64(1) << u32(f); active[f] = false; k--
			for v in 0 .. n { edge[f][v] = false; edge[v][f] = false }
		}
		mut staged := [max_fields]i64{}
		mut count := 0
		staged[count] = if infeasible { 0 } else { 1 }; count++
		staged[count] = k; count++
		staged[count] = i64(forced); count++
		mut active_mask := u64(0)
		for v in 0 .. n { if active[v] { active_mask |= u64(1) << u32(v) } }
		staged[count] = i64(active_mask); count++
		mut remaining := 0
		for u in 0 .. n { for v in u+1 .. n { if edge[u][v] { remaining++ } } }
		staged[count] = i64(remaining); count++
		for u in 0 .. n { for v in u+1 .. n { if edge[u][v] { staged[count] = i64(u); staged[count+1] = i64(v); count += 2 } } }
		if capacity < usize(8*count) { return -2 }
		for i in 0 .. count { put_i64_le(mut output, 8*i, staged[i]) }
		return i64(8*count)
	}
}
