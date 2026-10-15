module binary_tree_path_sum

const max_nodes = 63

fn count_from(input &i64, node int, sum i64, target i64) i64 {
	base := 2 + 3 * node
	mut count := if sum == target { i64(1) } else { i64(0) }
	unsafe {
		left := input[base + 1]
		right := input[base + 2]
		if left >= 0 { child := int(left); count += count_from(input, child, sum + input[2 + 3 * child], target) }
		if right >= 0 { child := int(right); count += count_from(input, child, sum + input[2 + 3 * child], target) }
	}
	return count
}

fn start_at_each_node(input &i64, node int) i64 {
	base := 2 + 3 * node
	mut count := count_from(input, node, unsafe { input[base] }, unsafe { input[0] })
	unsafe {
		left := input[base + 1]
		right := input[base + 2]
		if left >= 0 { count += start_at_each_node(input, int(left)) }
		if right >= 0 { count += start_at_each_node(input, int(right)) }
	}
	return count
}

@[export: 'binary_tree_path_sum']
pub fn binary_tree_path_sum(input &i64, length usize) i64 {
	unsafe {
		if length < 2 || input[1] < 0 || input[1] > max_nodes { return -1 }
		count := int(input[1])
		if length != usize(2 + 3 * count) { return -1 }
		if count == 0 { return 0 }
		mut parents := [max_nodes]int{}
		for node in 0 .. count {
			base := 2 + 3 * node
			if input[base] < -2147483648 || input[base] > 2147483647 { return -1 }
			for side in 1 .. 3 {
				child := input[base + side]
				if child < -1 || child >= count { return -1 }
				if child >= 0 { parents[int(child)]++; if parents[int(child)] > 1 { return -1 } }
			}
		}
		if parents[0] != 0 { return -1 }
		for node in 1 .. count { if parents[node] != 1 { return -1 } }
		mut seen := [max_nodes]bool{}
		mut stack := [max_nodes]int{}
		mut top := 1
		mut reached := 0
		stack[0] = 0
		for top > 0 {
			top--
			node := stack[top]
			if seen[node] { return -1 }
			seen[node] = true; reached++
			base := 2 + 3 * node
			if input[base + 1] >= 0 { stack[top] = int(input[base + 1]); top++ }
			if input[base + 2] >= 0 { stack[top] = int(input[base + 2]); top++ }
		}
		if reached != count { return -1 }
		return start_at_each_node(input, 0)
	}
}
