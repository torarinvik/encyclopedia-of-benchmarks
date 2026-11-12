module garsia_wachs_alphabetic_tree

const max_n = 64
const max_node = 2 * max_n - 1
const max_input = max_n + 2
const max_weight = 1_000_000
const gw_infinity = i64(1) << 62

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'garsia_wachs_alphabetic_tree']
pub fn garsia_wachs_alphabetic_tree(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > usize(max_input) { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > max_n { return -1 }
		n := int(n_value)
		if input_length != usize(n + 1) { return -1 }

		mut node_weight := [max_node]i64{}
		mut left := [max_node]int{}
		mut right := [max_node]int{}
		mut active := [max_n]int{}
		for i in 0 .. n {
			if input[i + 1] < 0 || input[i + 1] > max_weight { return -1 }
			node_weight[i] = input[i + 1]
			left[i] = -1
			right[i] = -1
			active[i] = i
		}
		mut active_count := n
		mut next_node := n
		for active_count > 1 {
			mut pair := 0
			for pair + 1 < active_count {
				mut following := gw_infinity
				if pair + 2 < active_count { following = node_weight[active[pair + 2]] }
				if node_weight[active[pair]] <= following { break }
				pair++
			}
			first := active[pair]
			second := active[pair + 1]
			combined := node_weight[first] + node_weight[second]
			node_weight[next_node] = combined
			left[next_node] = first
			right[next_node] = second
			mut earlier := pair
			for earlier > 0 && node_weight[active[earlier - 1]] < combined { earlier-- }
			insert_at := earlier
			mut i := pair
			for i + 2 < active_count {
				active[i] = active[i + 2]
				i++
			}
			active_count -= 2
			i = active_count
			for i > insert_at {
				active[i] = active[i - 1]
				i--
			}
			active[insert_at] = next_node
			active_count++
			next_node++
		}

		mut depths := [max_n]int{}
		mut stack_node := [2 * max_n]int{}
		mut stack_depth := [2 * max_n]int{}
		mut top := 1
		stack_node[0] = active[0]
		for top > 0 {
			top--
			node := stack_node[top]
			depth := stack_depth[top]
			if node < n {
				depths[node] = depth
			} else {
				stack_node[top] = right[node]
				stack_depth[top] = depth + 1
				top++
				stack_node[top] = left[node]
				stack_depth[top] = depth + 1
				top++
			}
		}

		mut ordered_left := [max_node]int{}
		mut ordered_right := [max_node]int{}
		mut code_node := [2 * max_n]int{}
		mut code_depth := [2 * max_n]int{}
		mut code_top := 0
		mut next_ordered := n
		for leaf in 0 .. n {
			code_node[code_top] = leaf
			code_depth[code_top] = depths[leaf]
			code_top++
			for code_top >= 2 && code_depth[code_top - 1] == code_depth[code_top - 2] {
				level := code_depth[code_top - 1]
				if level <= 0 || next_ordered >= 2 * n - 1 { return -1 }
				ordered_left[next_ordered] = code_node[code_top - 2]
				ordered_right[next_ordered] = code_node[code_top - 1]
				code_top -= 2
				code_node[code_top] = next_ordered
				code_depth[code_top] = level - 1
				code_top++
				next_ordered++
			}
		}
		if code_top != 1 || code_depth[0] != 0 || next_ordered != 2 * n - 1 { return -1 }

		mut cost := i64(0)
		for i in 0 .. n { cost += input[i + 1] * i64(depths[i]) }
		output_bytes := 8 * (n + 1)
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		put_i64(mut output, 0, cost)
		for i in 0 .. n { put_i64(mut output, 8 * (i + 1), i64(depths[i])) }
		return i64(output_bytes)
	}
}
