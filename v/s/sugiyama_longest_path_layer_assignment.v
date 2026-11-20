@[export: 'sugiyama_longest_path_layer_assignment']
pub fn sugiyama_longest_path_layer_assignment(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 259 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 0 || n64 > 32 || m64 < 0 || m64 > 128 { return -1 }
		n := int(n64)
		m := int(m64)
		if length != usize(2 + 2*m) { return -1 }

		mut adjacency := []u32{len: 32, init: 0}
		for edge in 0 .. m {
			source := input[2+2*edge]
			target := input[3+2*edge]
			if source < 0 || source >= n64 || target < 0 || target >= n64 { return -1 }
			bit := u32(1) << int(target)
			if adjacency[int(source)] & bit != 0 { return -1 }
			adjacency[int(source)] |= bit
		}

		mut removed := []bool{len: 32, init: false}
		mut sink_depth := []int{len: 32, init: 0}
		mut remaining := n
		mut depth := 0
		for remaining > 0 {
			mut sinks := []bool{len: 32, init: false}
			mut sink_count := 0
			for vertex in 0 .. n {
				if removed[vertex] { continue }
				mut has_successor := false
				for target in 0 .. n {
					if !removed[target] && adjacency[vertex] & (u32(1) << target) != 0 {
						has_successor = true
						break
					}
				}
				if !has_successor { sinks[vertex] = true; sink_count++ }
			}
			if sink_count == 0 { return -1 }
			for vertex in 0 .. n {
				if sinks[vertex] { removed[vertex] = true; sink_depth[vertex] = depth }
			}
			remaining -= sink_count
			depth++
		}

		output_bytes := 8 * (n + 1)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut values := []u64{len: n + 1, init: 0}
		values[0] = u64(depth)
		for vertex in 0 .. n { values[vertex+1] = u64(depth - 1 - sink_depth[vertex]) }
		for word in 0 .. n + 1 {
			for byte in 0 .. 8 {
				output[word*8+byte] = u8(values[word] >> (8*byte))
			}
		}
		return i64(output_bytes)
	}
}
