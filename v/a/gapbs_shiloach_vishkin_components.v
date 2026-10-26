@[export: 'gapbs_shiloach_vishkin_components']
pub fn gapbs_shiloach_vishkin_components(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 130 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || length != usize(2+2*m64) { return -1 }
		n := int(n64)
		m := int(m64)
		mut adjacency := []bool{len: 256, init: false}
		for edge in 0 .. m {
			pos := 2 + 2*edge
			u := input[pos]
			v := input[pos+1]
			if u < 0 || v <= u || v >= n64 { return -1 }
			ui := int(u)
			vi := int(v)
			if adjacency[ui*16+vi] { return -1 }
			adjacency[ui*16+vi] = true
			adjacency[vi*16+ui] = true
		}
		output_bytes := 8*n
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut component := []int{len: 16, init: 0}
		for node in 0 .. n { component[node] = node }
		mut changed := true
		mut rounds := 0
		round_limit := n*n + 1
		for changed && rounds < round_limit {
			changed = false
			for u in 0 .. n {
				for v in 0 .. n {
					if !adjacency[u*16+v] { continue }
					component_u := component[u]
					component_v := component[v]
					if component_u == component_v { continue }
					high := if component_u > component_v { component_u } else { component_v }
					low := if component_u < component_v { component_u } else { component_v }
					if component[high] == high { changed = true; component[high] = low }
				}
			}
			for node in 0 .. n {
				for component[node] != component[component[node]] { component[node] = component[component[node]] }
			}
			rounds++
		}
		if changed { return -1 }
		for node in 0 .. n {
			bits := u64(component[node])
			for byte in 0 .. 8 { output[8*node+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
