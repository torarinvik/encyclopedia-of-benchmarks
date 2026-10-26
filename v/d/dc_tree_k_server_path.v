module dc_tree_k_server_path

fn put_i64(out &u8, offset int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { out[offset+b] = u8((bits >> (8*b)) & 255) } }
}

@[export: 'dc_tree_k_server_path']
pub fn dc_tree_k_server_path(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == unsafe { nil } || length < 5 || length > 18 { return -1 }
	k0 := unsafe { input[0] }; q0 := unsafe { input[1] }
	if k0 < 2 || k0 > 4 || q0 < 1 || q0 > 12 { return -1 }
	k := int(k0); q := int(q0)
	if length != usize(2+k+q) { return -1 }
	mut pos := [4]i64{}
	for i in 0 .. k { pos[i] = unsafe { input[2+i] }; if pos[i] < 0 || pos[i] > 15 { return -1 } }
	for r in 0 .. q { x := unsafe { input[2+k+r] }; if x < 0 || x > 15 { return -1 } }
	mut staged := [60]i64{}
	mut at := 0
	for r in 0 .. q {
		target := unsafe { input[2+k+r] }
		mut active := [4]bool{}
		mut active_count := 0
		mut nearest := i64(9223372036854775807)
		for i in 0 .. k {
			mut first := true
			for j in 0 .. i { if pos[j] == pos[i] { first = false; break } }
			if !first { continue }
			active[i] = true; active_count++
			mut delta := pos[i]-target; if delta < 0 { delta = -delta }; if delta < nearest { nearest = delta }
		}
		staged[at] = nearest*i64(active_count); at++
		for i in 0 .. k {
			if active[i] { if pos[i] < target { pos[i] += nearest } else if pos[i] > target { pos[i] -= nearest } }
		}
		for i in 0 .. k { staged[at] = pos[i]; at++ }
	}
	bytes := 8*q*(k+1)
	if output == unsafe { nil } || capacity < usize(bytes) { return -2 }
	for i in 0 .. at { put_i64(mut output, 8*i, staged[i]) }
	return i64(bytes)
}
