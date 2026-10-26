module streaming_triangles

fn power(base int, exponent int) i64 {
	mut value := i64(1)
	for _ in 0 .. exponent { value *= i64(base) }
	return value
}
fn make_wedge(a [2]i64, b [2]i64, mut out [2]i64) bool {
	mut common := i64(-1)
	for x in a { for y in b { if x == y { common = x } } }
	if common < 0 { return false }
	mut x := if a[0] == common { a[1] } else { a[0] }
	mut y := if b[0] == common { b[1] } else { b[0] }
	if x == y { return false }
	if x > y { x, y = y, x }
	out[0] = x; out[1] = y
	return true
}
fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset+b] = u8((bits >> u64(8*b)) & 255) } }
}

@[export: 'streaming_triangles']
pub fn streaming_triangles(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 10 || length > 340 { return -1 }
	unsafe {
		n0, m0, se0, sw0 := input[0], input[1], input[2], input[3]
		if n0 < 2 || n0 > 8 || m0 < 1 || m0 > 28 || se0 < 2 || se0 > 4 || sw0 < 1 || sw0 > 4 { return -1 }
		m, se, sw := int(m0), int(se0), int(sw0)
		stride := 2 + 2 * sw
		if length != usize(4+2*m+m*stride) { return -1 }
		mut edge_u := []i64{len: 28, init: 0}; mut edge_v := []i64{len: 28, init: 0}; mut seen := []bool{len: 64, init: false}
		for i in 0 .. m {
			u, v := input[4+2*i], input[5+2*i]
			if u < 0 || v <= u || v >= n0 || seen[int(u)*8+int(v)] { return -1 }
			seen[int(u)*8+int(v)] = true; seen[int(v)*8+int(u)] = true
			edge_u[i] = u; edge_v[i] = v
		}
		mut edge_res := []int{len: 4, init: -1}; mut wedge_u := []i64{len: 4, init: 0}; mut wedge_v := []i64{len: 4, init: 0}
		mut wedge_valid := []bool{len: 4, init: false}; mut closed := []bool{len: 4, init: false}
		mut staged := []i64{len: 84, init: 0}; mut total := i64(0); mut at := 0; tape := 4+2*m
		for ti in 0 .. m {
			t := ti+1; rec := tape+ti*stride
			for s in 0 .. sw { if wedge_valid[s] && wedge_u[s] == edge_u[ti] && wedge_v[s] == edge_v[ti] { closed[s] = true } }
			draw, slot0 := input[rec], input[rec+1]
			limit := power(t,se); threshold := limit-power(t-1,se)
			if draw < 0 || draw >= limit { return -1 }
			update := draw < threshold
			mut fresh_u := []i64{len: 4, init: 0}; mut fresh_v := []i64{len: 4, init: 0}; mut fresh_count := 0; mut removed_count := 0
			if update {
				if slot0 < 0 || slot0 >= i64(se) { return -1 }
				slot := int(slot0); old_id := edge_res[slot]
				if old_id >= 0 {
					for j in 0 .. se { if j != slot && edge_res[j] >= 0 {
						old := int(edge_res[j]); mut prior := [2]i64{}
						if make_wedge([edge_u[int(old_id)],edge_v[int(old_id)]],[edge_u[old],edge_v[old]],mut prior) { removed_count++ }
					} }
				}
				edge_res[slot] = ti
				for j in 0 .. se {
					if j != slot && edge_res[j] >= 0 {
						old := int(edge_res[j]); mut result := [2]i64{}
						if make_wedge([edge_u[ti],edge_v[ti]],[edge_u[old],edge_v[old]],mut result) { fresh_u[fresh_count]=result[0];fresh_v[fresh_count]=result[1];fresh_count++ }
					}
				}
			} else if slot0 != 0 { return -1 }
			total += i64(fresh_count-removed_count)
			if total < 0 { return -1 }
			for s in 0 .. sw {
				wd,pick := input[rec+2+2*s],input[rec+3+2*s]
				if fresh_count > 0 {
					if wd < 0 || wd >= total { return -1 }
					if wd < i64(fresh_count) {
						if pick < 0 || pick >= i64(fresh_count) { return -1 }
						wedge_u[s]=fresh_u[int(pick)];wedge_v[s]=fresh_v[int(pick)];wedge_valid[s]=true;closed[s]=false
					} else if pick != 0 { return -1 }
				} else if wd != 0 || pick != 0 { return -1 }
			}
			mut hits := i64(0);for s in 0 .. sw { if closed[s] { hits++ } }
			staged[at]=total;staged[at+1]=(3*hits*1000000)/i64(sw);staged[at+2]=(hits*i64(t)*i64(t)*total*1000000)/i64(sw*se*(se-1));at+=3
		}
		bytes := usize(24*m)
		if output == nil || capacity < bytes { return -2 }
		for i in 0 .. at { put_i64(mut output,i*8,staged[i]) }
		return i64(bytes)
	}
}
