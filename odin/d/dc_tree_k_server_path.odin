package dc_tree_k_server_path

import "core:c"

put_i64 :: proc(out: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for b in 0..<8 { out[offset+b] = u8((bits >> (8*b)) & 255) }
}

@(export)
dc_tree_k_server_path :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 18 do return -1
	k0, q0 := input[0], input[1]
	if k0 < 2 || k0 > 4 || q0 < 1 || q0 > 12 do return -1
	k, q := int(k0), int(q0)
	if int(length) != 2+k+q do return -1
	pos: [4]i64
	for i in 0..<k { pos[i] = input[2+i]; if pos[i] < 0 || pos[i] > 15 do return -1 }
	for r in 0..<q { if input[2+k+r] < 0 || input[2+k+r] > 15 do return -1 }
	staged: [60]i64
	at := 0
	for r in 0..<q {
		target := input[2+k+r]
		active: [4]bool
		active_count := 0
		nearest := i64(9223372036854775807)
		for i in 0..<k {
			first := true
			for j in 0..<i { if pos[j] == pos[i] { first = false; break } }
			if !first do continue
			active[i] = true; active_count += 1
			delta := pos[i]-target; if delta < 0 { delta = -delta }; if delta < nearest { nearest = delta }
		}
		staged[at] = nearest*i64(active_count); at += 1
		for i in 0..<k {
			if active[i] {
				if pos[i] < target { pos[i] += nearest } else if pos[i] > target { pos[i] -= nearest }
			}
		}
		for i in 0..<k { staged[at] = pos[i]; at += 1 }
	}
	bytes := 8*q*(k+1)
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i in 0..<at { put_i64(output, 8*i, staged[i]) }
	return i64(bytes)
}
