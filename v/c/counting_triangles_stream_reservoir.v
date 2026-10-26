module counting_triangles_stream_reservoir

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8((bits >> u64(8*b)) & 255) } }
}

@[export: 'counting_triangles_stream_reservoir']
pub fn counting_triangles_stream_reservoir(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 6 || length > 114 { return -1 }
	unsafe {
		n0, m0 := input[0], input[1]
		if n0 < 2 || n0 > 8 || m0 < 1 || m0 > 28 || length != usize(2+4*m0) { return -1 }
		n, m := int(n0), int(m0)
		mut seen := []bool{len: 64, init: false}
		mut edges_u := []i64{len: 28, init: 0}; mut edges_v := []i64{len: 28, init: 0}
		for i in 0 .. m {
			u, v := input[2+2*i], input[3+2*i]
			if u < 0 || v <= u || v >= n0 || seen[int(u)*8+int(v)] { return -1 }
			seen[int(u)*8+int(v)] = true; seen[int(v)*8+int(u)] = true
			edges_u[i] = u; edges_v[i] = v
		}
		base := 2+2*m
		for t in 1 .. m+1 { for s in 0 .. 2 {
			r := input[base+2*(t-1)+s]
			if r < 0 || r >= i64(t) { return -1 }
		} }
		mut slot_u := []i64{len: 2, init: -1}; mut slot_v := []i64{len: 2, init: -1}
		mut staged := []i64{len: 112, init: 0}; mut at := 0
		for t in 1 .. m+1 {
			for s in 0 .. 2 { if input[base+2*(t-1)+s] == 0 { slot_u[s] = edges_u[t-1]; slot_v[s] = edges_v[t-1] } }
			for s in 0 .. 2 { staged[at] = slot_u[s]; at++; staged[at] = slot_v[s]; at++ }
		}
		bytes := usize(16*m)
		if output == nil || capacity < bytes { return -2 }
		for i in 0 .. at { put_i64(mut output, i*8, staged[i]) }
		return i64(bytes)
	}
}
