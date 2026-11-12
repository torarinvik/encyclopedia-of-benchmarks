module lowest_common_ancestor_farach_colton_bender

const max_nodes = 256
const max_queries = 1024
const max_arcs = 510
const max_euler = 2 * max_nodes - 1
const max_blocks = 128
const max_levels = 8
const max_micro = 4

@[export: 'lowest_common_ancestor_farach_colton_bender']
pub fn lowest_common_ancestor_farach_colton_bender(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 { return -1 }
		if input[0] < 1 || input[0] > max_nodes { return -1 }
		n := int(input[0])
		if input[1] < 0 || input[1] >= i64(n) || input[2] != i64(n - 1) || input[3] < 0 || input[3] > max_queries { return -1 }
		edge_count := int(input[2])
		query_count := int(input[3])
		query_offset := 4 + 2 * edge_count
		if length != usize(query_offset + 2 * query_count) { return -1 }
		root := int(input[1])

		mut head := [max_nodes]int{}
		mut arc_to := [max_arcs]int{}
		mut arc_next := [max_arcs]int{}
		mut parent := [max_nodes]int{}
		mut tree_depth := [max_nodes]int{}
		mut first := [max_nodes]int{}
		mut euler := [max_euler]int{}
		mut euler_depth := [max_euler]int{}
		mut stack_node := [max_nodes]int{}
		mut stack_arc := [max_nodes]int{}
		for node in 0 .. n { head[node] = -1; parent[node] = -2 }
		mut arcs := 0
		for edge in 0 .. edge_count {
			u_value := input[4 + 2 * edge]
			v_value := input[5 + 2 * edge]
			if u_value < 0 || u_value >= i64(n) || v_value < 0 || v_value >= i64(n) || u_value == v_value { return -1 }
			u := int(u_value)
			v := int(v_value)
			arc_to[arcs] = v; arc_next[arcs] = head[u]; head[u] = arcs; arcs++
			arc_to[arcs] = u; arc_next[arcs] = head[v]; head[v] = arcs; arcs++
		}
		for query in 0 .. query_count {
			for side in 0 .. 2 {
				node := input[query_offset + 2 * query + side]
				if node < 0 || node >= i64(n) { return -1 }
			}
		}

		mut euler_count := 1
		mut top := 1
		mut reached := 1
		parent[root] = -1
		first[root] = 0
		euler[0] = root
		stack_node[0] = root
		stack_arc[0] = head[root]
		for top > 0 {
			slot := top - 1
			node := stack_node[slot]
			arc := stack_arc[slot]
			if arc < 0 {
				top--
				if top > 0 {
					up := stack_node[top - 1]
					euler[euler_count] = up
					euler_depth[euler_count] = tree_depth[up]
					euler_count++
				}
				continue
			}
			stack_arc[slot] = arc_next[arc]
			neighbor := arc_to[arc]
			if neighbor == parent[node] { continue }
			if parent[neighbor] != -2 { return -1 }
			parent[neighbor] = node
			tree_depth[neighbor] = tree_depth[node] + 1
			first[neighbor] = euler_count
			euler[euler_count] = neighbor
			euler_depth[euler_count] = tree_depth[neighbor]
			euler_count++
			reached++
			stack_node[top] = neighbor
			stack_arc[top] = head[neighbor]
			top++
		}
		if reached != n { return -1 }
		if output_capacity < usize(query_count) || (query_count > 0 && output == nil) { return -2 }

		mut logarithm := 0
		mut value := euler_count
		for value > 1 { value /= 2; logarithm++ }
		mut block_size := logarithm / 2
		if block_size < 1 { block_size = 1 }
		block_count := (euler_count + block_size - 1) / block_size
		mut micro := [8 * max_micro * max_micro]int{}
		mut pattern := [max_blocks]int{}
		mut logs := [max_blocks + 1]int{}
		mut macro := [max_levels * max_blocks]int{}
		for shape in 0 .. (1 << (block_size - 1)) {
			mut relative := [max_micro]int{}
			for step in 0 .. (block_size - 1) {
				direction := if ((shape >> step) & 1) != 0 { 1 } else { -1 }
				relative[step + 1] = relative[step] + direction
			}
			for left in 0 .. block_size {
				for right := left; right < block_size; right++ {
					mut best := left
					for at := left + 1; at <= right; at++ { if relative[at] < relative[best] { best = at } }
					micro[shape * 16 + left * 4 + right] = best
				}
			}
		}
		for block in 0 .. block_count {
			base := block * block_size
			end := min(euler_count, base + block_size)
			mut best := base
			for at := base; at + 1 < end; at++ {
				if euler_depth[at + 1] > euler_depth[at] { pattern[block] |= 1 << (at - base) }
				candidate := at + 1
				if euler_depth[candidate] < euler_depth[best] || (euler_depth[candidate] == euler_depth[best] && candidate < best) { best = candidate }
			}
			macro[block] = best
		}
		for count in 2 .. (block_count + 1) { logs[count] = logs[count / 2] + 1 }
		mut macro_levels := 1
		for (1 << macro_levels) <= block_count && macro_levels < max_levels {
			half := 1 << (macro_levels - 1)
			span := 2 * half
			for block in 0 .. (block_count - span + 1) {
				a := macro[(macro_levels - 1) * max_blocks + block]
				b := macro[(macro_levels - 1) * max_blocks + block + half]
				best := if euler_depth[a] < euler_depth[b] || (euler_depth[a] == euler_depth[b] && a < b) { a } else { b }
				macro[macro_levels * max_blocks + block] = best
			}
			macro_levels++
		}

		mut answers := [max_queries]u8{}
		for query in 0 .. query_count {
			u := int(input[query_offset + 2 * query])
			v := int(input[query_offset + 2 * query + 1])
			mut left := first[u]
			mut right := first[v]
			if left > right { temp := left; left = right; right = temp }
			block_a := left / block_size
			block_b := right / block_size
			mut best := 0
			if block_a == block_b {
				best = block_a * block_size + micro[pattern[block_a] * 16 + (left % block_size) * 4 + (right % block_size)]
			} else {
				base_a := block_a * block_size
				base_b := block_b * block_size
				len_a := min(block_size, euler_count - base_a)
				best = base_a + micro[pattern[block_a] * 16 + (left % block_size) * 4 + len_a - 1]
				right_best := base_b + micro[pattern[block_b] * 16 + (right % block_size)]
				if euler_depth[right_best] < euler_depth[best] || (euler_depth[right_best] == euler_depth[best] && right_best < best) { best = right_best }
				if block_b > block_a + 1 {
					lo := block_a + 1
					hi := block_b - 1
					count := hi - lo + 1
					level := logs[count]
					span := 1 << level
					a := macro[level * max_blocks + lo]
					b := macro[level * max_blocks + hi - span + 1]
					middle := if euler_depth[a] < euler_depth[b] || (euler_depth[a] == euler_depth[b] && a < b) { a } else { b }
					if euler_depth[middle] < euler_depth[best] || (euler_depth[middle] == euler_depth[best] && middle < best) { best = middle }
				}
			}
			answers[query] = u8(euler[best])
		}
		for query in 0 .. query_count { output[query] = answers[query] }
		return i64(query_count)
	}
}
