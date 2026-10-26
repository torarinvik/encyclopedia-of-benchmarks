@[export: 'gbbs_maximal_matching']
pub fn gbbs_maximal_matching(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 194 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || length != usize(2+3*m64) { return -1 }
		m := int(m64)
		edge_start := 2 + m
		mut rank_seen := []bool{len: 64, init: false}
		mut order := []int{len: 64, init: 0}
		for edge in 0 .. m {
			rank64 := input[2+edge]
			if rank64 < 0 || rank64 >= m64 { return -1 }
			rank := int(rank64)
			if rank_seen[rank] { return -1 }
			rank_seen[rank] = true
			order[rank] = edge
			u64 := input[edge_start+2*edge]
			v64 := input[edge_start+2*edge+1]
			if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1 }
			for prior in 0 .. edge {
				if input[edge_start+2*prior] == u64 && input[edge_start+2*prior+1] == v64 { return -1 }
			}
		}
		output_bytes := 8*m
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut matched := []bool{len: 16, init: false}
		mut selected := []i64{len: 64, init: 0}
		for rank in 0 .. m {
			edge := order[rank]
			u := int(input[edge_start+2*edge])
			v := int(input[edge_start+2*edge+1])
			if !matched[u] && !matched[v] {
				selected[edge] = 1
				matched[u] = true
				matched[v] = true
			}
		}
		for edge in 0 .. m {
			bits := u64(selected[edge])
			for byte in 0 .. 8 { output[8*edge+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
