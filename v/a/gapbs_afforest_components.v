// Clean-room bounded GAPBS Afforest profile; see package LICENSE.txt.
@[export: 'gapbs_afforest_components']
pub fn gapbs_afforest_components(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 195 { return -1 }
		n64 := input[0]
		m64 := input[1]
		sample_count64 := input[2]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || sample_count64 < 1 || sample_count64 > 64 { return -1 }
		n := int(n64)
		m := int(m64)
		sample_count := int(sample_count64)
		if length != usize(3 + sample_count + 2*m) { return -1 }
		mut samples := []int{len: 64, init: 0}
		for i in 0 .. sample_count {
			sample := input[3+i]
			if sample < 0 || sample >= n64 { return -1 }
			samples[i] = int(sample)
		}
		mut adjacency := []bool{len: 256, init: false}
		for edge in 0 .. m {
			pos := 3 + sample_count + 2*edge
			u := input[pos]
			v := input[pos+1]
			if u < 0 || v <= u || v >= n64 || adjacency[int(u)*16+int(v)] { return -1 }
			adjacency[int(u)*16+int(v)] = true
			adjacency[int(v)*16+int(u)] = true
		}
		output_bytes := 8*n
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut neighbors := []int{len: 256, init: 0}
		mut degree := []int{len: 16, init: 0}
		for u in 0 .. n {
			for v in 0 .. n {
				if adjacency[u*16+v] { neighbors[u*16+degree[u]] = v; degree[u]++ }
			}
		}
		mut component := []int{len: 16, init: 0}
		for vertex in 0 .. n { component[vertex] = vertex }
		for round in 0 .. 2 {
			for u in 0 .. n {
				if degree[u] > round { link_components(u, neighbors[u*16+round], mut component) }
			}
			compress_components(n, mut component)
		}
		mut sample_counts := []int{len: 16, init: 0}
		for i in 0 .. sample_count { sample_counts[component[samples[i]]]++ }
		mut skip_label := 0
		for label in 1 .. n {
			if sample_counts[label] > sample_counts[skip_label] { skip_label = label }
		}
		mut skip_is_safe := true
		for u in 0 .. n {
			if component[u] != skip_label { continue }
			for offset in 2 .. degree[u] {
				if component[neighbors[u*16+offset]] != skip_label { skip_is_safe = false; break }
			}
			if !skip_is_safe { break }
		}
		for u in 0 .. n {
			if skip_is_safe && component[u] == skip_label { continue }
			for offset in 2 .. degree[u] { link_components(u, neighbors[u*16+offset], mut component) }
		}
		compress_components(n, mut component)
		for vertex in 0 .. n {
			bits := u64(component[vertex])
			for byte in 0 .. 8 { output[8*vertex+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}

fn link_components(u int, v int, mut component []int) {
	mut p1 := component[u]
	mut p2 := component[v]
	for p1 != p2 {
		high := if p1 > p2 { p1 } else { p2 }
		low := if p1 < p2 { p1 } else { p2 }
		parent_high := component[high]
		if parent_high == low { break }
		if parent_high == high { component[high] = low; break }
		p1 = component[component[high]]
		p2 = component[low]
	}
}

fn compress_components(n int, mut component []int) {
	for vertex in 0 .. n {
		for component[vertex] != component[component[vertex]] { component[vertex] = component[component[vertex]] }
	}
}
