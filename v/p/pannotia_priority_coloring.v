@[export: 'pannotia_priority_coloring']
pub fn pannotia_priority_coloring(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 147 { return -1 }
		n64 := input[0]
		m64 := input[1]
		mode64 := input[2]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || (mode64 != 0 && mode64 != 1) || length != usize(3+n64+2*m64) { return -1 }
		n := int(n64)
		m := int(m64)
		mode := int(mode64)
		mut adjacency := []u64{len: 16, init: 0}
		mut degree := []int{len: 16, init: 0}
		mut priority := []i64{len: 16, init: 0}
		mut color := []i64{len: 16, init: -1}
		mut active := []bool{len: 16, init: false}
		for v in 0 .. n {
			priority[v] = input[3+v]
			if priority[v] < 0 || priority[v] > 99999998 { return -1 }
			for prior in 0 .. v { if priority[prior] == priority[v] { return -1 } }
			active[v] = true
		}
		for edge in 0 .. m {
			u_value := input[3+n+2*edge]
			v_value := input[4+n+2*edge]
			if u_value < 0 || v_value <= u_value || v_value >= n64 { return -1 }
			u := int(u_value)
			v := int(v_value)
			bit := u64(1) << v
			if adjacency[u] & bit != 0 { return -1 }
			adjacency[u] |= bit
			adjacency[v] |= u64(1) << u
			degree[u]++
			degree[v]++
		}
		for v in 0 .. n { if degree[v] == 1 { return -1 } }
		output_bytes := 8*n
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut current_color := i64(1)
		for {
			mut chosen := []bool{len: 16, init: false}
			mut chosen_count := 0
			for v in 0 .. n {
				if !active[v] { continue }
				mut maximum := i64(-1)
				mut minimum := i64(99999999)
				for u in 0 .. n {
					if active[u] && adjacency[v] & (u64(1) << u) != 0 {
						if priority[u] > maximum { maximum = priority[u] }
						if priority[u] < minimum { minimum = priority[u] }
					}
				}
				if priority[v] > maximum { color[v] = current_color; chosen[v] = true }
				if mode == 1 && priority[v] < minimum { color[v] = current_color+1; chosen[v] = true }
				if chosen[v] { chosen_count++ }
			}
			if chosen_count == 0 { return -1 }
			for v in 0 .. n { if chosen[v] { active[v] = false } }
			mut remaining := false
			for v in 0 .. n { remaining = remaining || active[v] }
			if !remaining { break }
			current_color += if mode == 1 { i64(2) } else { i64(1) }
		}
		for v in 0 .. n {
			bits := u64(color[v])
			for byte in 0 .. 8 { output[8*v+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
