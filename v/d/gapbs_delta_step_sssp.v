// Clean-room bounded GAPBS delta-stepping profile; see package LICENSE.txt.
@[export: 'gapbs_delta_step_sssp']
pub fn gapbs_delta_step_sssp(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 196 { return -1 }
		n64 := input[0]
		m64 := input[1]
		source64 := input[2]
		delta := input[3]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || source64 < 0 || source64 >= n64 || delta < 1 || delta > 16 || length != usize(4+3*m64) { return -1 }
		n := int(n64)
		m := int(m64)
		source := int(source64)
		mut edge_from := []int{len: 64, init: 0}
		mut edge_to := []int{len: 64, init: 0}
		mut edge_weight := []i64{len: 64, init: 0}
		for edge in 0 .. m {
			from := input[4+3*edge]
			to := input[5+3*edge]
			weight := input[6+3*edge]
			if from < 0 || from >= n64 || to < 0 || to >= n64 || weight < 0 || weight > 32 { return -1 }
			edge_from[edge] = int(from)
			edge_to[edge] = int(to)
			edge_weight[edge] = weight
		}
		output_bytes := 8*n
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut distance := []i64{len: 16, init: 1073741823}
		distance[source] = 0
		mut heads := []int{len: 481, init: -1}
		mut tails := []int{len: 481, init: -1}
		mut event_vertex := []int{len: 8192, init: 0}
		mut event_next := []int{len: 8192, init: -1}
		mut used := 0
		event_vertex[0] = source
		event_next[0] = -1
		heads[0] = 0
		tails[0] = 0
		used = 1
		for bucket in 0 .. 481 {
			for heads[bucket] >= 0 {
				event := heads[bucket]
				heads[bucket] = event_next[event]
				if heads[bucket] < 0 { tails[bucket] = -1 }
				u := event_vertex[event]
				if distance[u] >= i64(bucket)*delta {
					for edge in 0 .. m {
						if edge_from[edge] != u { continue }
						v := edge_to[edge]
						candidate := distance[u] + edge_weight[edge]
						if candidate < distance[v] {
							distance[v] = candidate
							destination := int(candidate / delta)
							if used >= 8192 || destination < 0 || destination >= 481 { return -1 }
							entry := used
							used++
							event_vertex[entry] = v
							event_next[entry] = -1
							if heads[destination] < 0 { heads[destination] = entry } else { event_next[tails[destination]] = entry }
							tails[destination] = entry
						}
					}
				}
			}
		}
		for vertex in 0 .. n {
			bits := u64(distance[vertex])
			for byte in 0 .. 8 { output[8*vertex+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
