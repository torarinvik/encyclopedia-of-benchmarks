@[export: 'pannotia_local_minimum_mis']
pub fn pannotia_local_minimum_mis(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 146 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || length != usize(2+n64+2*m64) { return -1 }
		n := int(n64)
		m := int(m64)
		mut adjacency := []u64{len: 16, init: 0}
		mut priority := []i64{len: 16, init: 0}
		for v in 0 .. n {
			priority[v] = input[2+v]
			if priority[v] < 0 || priority[v] > 99999998 { return -1 }
			for prior in 0 .. v { if priority[prior] == priority[v] { return -1 } }
		}
		for edge in 0 .. m {
			u_value := input[2+n+2*edge]
			v64 := input[3+n+2*edge]
			if u_value < 0 || v64 <= u_value || v64 >= n64 { return -1 }
			u := int(u_value)
			v := int(v64)
			bit := u64(1) << v
			if adjacency[u] & bit != 0 { return -1 }
			adjacency[u] |= bit
			adjacency[v] |= u64(1) << u
		}
		output_bytes := 8*n
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut active := []bool{len: 16, init: false}
		mut selected := []bool{len: 16, init: false}
		for v in 0 .. n { active[v] = true }
		for {
			mut chosen := []bool{len: 16, init: false}
			mut chosen_count := 0
			for v in 0 .. n {
				if !active[v] { continue }
				mut local_minimum := true
				for u in 0 .. n {
					if active[u] && adjacency[v] & (u64(1) << u) != 0 && priority[u] < priority[v] { local_minimum = false }
				}
				if local_minimum { chosen[v] = true; chosen_count++ }
			}
			if chosen_count == 0 { return -1 }
			for v in 0 .. n { if chosen[v] { selected[v] = true; active[v] = false } }
			for v in 0 .. n {
				if !chosen[v] { continue }
				for u in 0 .. n { if active[u] && adjacency[v] & (u64(1) << u) != 0 { active[u] = false } }
			}
			mut remaining := false
			for v in 0 .. n { remaining = remaining || active[v] }
			if !remaining { break }
		}
		for v in 0 .. n {
			value := if selected[v] { i64(2) } else { i64(0) }
			bits := u64(value)
			for byte in 0 .. 8 { output[8*v+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
