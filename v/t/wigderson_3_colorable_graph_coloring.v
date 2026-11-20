@[export: 'wigderson_3_colorable_graph_coloring']
pub fn wigderson_3_colorable_graph_coloring(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 259 { return -1 }
		if input[0] < 0 || input[0] > 32 || input[1] < 0 || input[1] > 128 { return -1 }
		n := int(input[0])
		m := int(input[1])
		if int(length) != 2 + 2*m { return -1 }
		mut adjacent := [1024]bool{}
		for edge in 0 .. m {
			ru := input[2 + 2*edge]
			rv := input[3 + 2*edge]
			if ru < 0 || rv <= ru || rv >= i64(n) { return -1 }
			u, v := int(ru), int(rv)
			uv, vu := u*32+v, v*32+u
			if adjacent[uv] { return -1 }
			adjacent[uv], adjacent[vu] = true, true
		}
		mut active := [32]bool{}
		mut colors := [32]u8{}
		for v in 0 .. n { active[v] = true }
		mut threshold := 0
		for (threshold+1)*(threshold+1) <= n { threshold++ }
		mut next_color := 1
		for {
			mut chosen, mut maximum_degree := n, 0
			for v in 0 .. n {
				if !active[v] { continue }
				mut degree := 0
				for w in 0 .. n { if active[w] && adjacent[v*32+w] { degree++ } }
				if chosen == n || degree > maximum_degree { chosen, maximum_degree = v, degree }
			}
			if chosen == n || maximum_degree < threshold { break }
			mut in_neighborhood := [32]bool{}
			mut side := [32]i8{}
			mut queue := [32]int{}
			for v in 0 .. n {
				side[v] = -1
				in_neighborhood[v] = active[v] && adjacent[chosen*32+v]
			}
			for root in 0 .. n {
				if !in_neighborhood[root] || side[root] >= 0 { continue }
				mut head, mut tail := 0, 0
				side[root] = 0
				queue[tail] = root
				tail++
				for head < tail {
					u := queue[head]
					head++
					for v in 0 .. n {
						if !in_neighborhood[v] || !adjacent[u*32+v] { continue }
						if side[v] < 0 {
							side[v] = 1 - side[u]
							queue[tail] = v
							tail++
						} else if side[v] == side[u] { return -1 }
					}
				}
			}
			for v in 0 .. n { if in_neighborhood[v] { colors[v] = u8(next_color + int(side[v])) } }
			colors[chosen] = u8(next_color + 2)
			active[chosen] = false
			for v in 0 .. n { if adjacent[chosen*32+v] { active[v] = false } }
			next_color += 2
		}
		for v in 0 .. n {
			if !active[v] { continue }
			mut used := [34]bool{}
			for w in 0 .. n {
				if adjacent[v*32+w] && colors[w] > 0 { used[int(colors[w])] = true }
			}
			mut candidate := next_color
			for candidate < used.len && used[candidate] { candidate++ }
			if candidate >= used.len { return -1 }
			colors[v] = u8(candidate)
		}
		mut palette := u8(0)
		for v in 0 .. n { if colors[v] > palette { palette = colors[v] } }
		output_bytes := n + 1
		if output == nil || capacity < usize(output_bytes) { return -2 }
		output[0] = palette
		for v in 0 .. n { output[v+1] = colors[v] }
		return i64(output_bytes)
	}
}
