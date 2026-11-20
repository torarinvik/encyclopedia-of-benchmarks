module order_preserving_huffman_greedy_trace

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[offset + b] = u8((bits >> (8 * b)) & 255) } }
}

@[export: 'order_preserving_huffman_greedy_trace']
pub fn order_preserving_huffman_greedy_trace(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 10 { return -1 }
		raw_n := input[0]
		if raw_n < 2 || raw_n > 8 || length != usize(raw_n + 1) { return -1 }
		n := int(raw_n)
		mut weights := [15]i64{}
		mut left := [15]int{}
		mut right := [15]int{}
		mut active := [8]int{}
		for i in 0 .. 15 { left[i] = -1; right[i] = -1 }
		mut total := i64(0)
		for i in 0 .. n {
			w := input[i + 1]
			if w < 1 || w > 15 { return -1 }
			weights[i] = w; total += w; active[i] = i
		}
		if total > 120 { return -1 }
		mut count := n
		mut next_node := n
		for count > 1 {
			mut pair := 0
			mut best := weights[active[0]] + weights[active[1]]
			for i in 1 .. count - 1 {
				candidate := weights[active[i]] + weights[active[i + 1]]
				if candidate < best { pair = i; best = candidate }
			}
			a := active[pair]
			b := active[pair + 1]
			weights[next_node] = best; left[next_node] = a; right[next_node] = b
			mut i := pair
			for i + 2 < count { active[i] = active[i + 2]; i++ }
			count -= 2
			i = count
			for i > pair { active[i] = active[i - 1]; i-- }
			active[pair] = next_node
			count++; next_node++
		}
		mut depths := [8]i64{}
		mut stack_node := [16]int{}
		mut stack_depth := [16]int{}
		mut top := 1
		stack_node[0] = active[0]
		stack_depth[0] = 0
		for top > 0 {
			top--
			node := stack_node[top]
			depth := stack_depth[top]
			if node < n { depths[node] = i64(depth) }
			else {
				stack_node[top] = left[node]; stack_depth[top] = depth + 1; top++
				stack_node[top] = right[node]; stack_depth[top] = depth + 1; top++
			}
		}
		mut words := [10]i64{}
		words[0] = raw_n
		for i in 0 .. n { words[1] += input[i + 1] * depths[i]; words[i + 2] = depths[i] }
		needed := 8 * (n + 2)
		mut staged := [80]u8{}
		for i in 0 .. n + 2 { put_i64(mut staged[0], 8 * i, words[i]) }
		if output == nil || capacity < usize(needed) { return -2 }
		for i in 0 .. needed { output[i] = staged[i] }
		return i64(needed)
	}
}
