module distribute_coins

const max_node_count = 100

fn absolute_i64(value i64) i64 {
	return if value < 0 { -value } else { value }
}

fn analyze(nodes &i64, node i64, mut moves &i64) i64 {
	if node == -1 { return 1 }
	index := usize(node)
	unsafe {
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		left_excess := analyze(nodes, left, mut moves)
		right_excess := analyze(nodes, right, mut moves)
		moves[0] += absolute_i64(1 - left_excess) + absolute_i64(1 - right_excess)
		return nodes[3 * index] + left_excess + right_excess - 2
	}
}

@[export: 'distribute_coins']
pub fn distribute_coins(nodes &i64, node_count usize, root_index i64) i64 {
	if node_count > max_node_count { return -1 }
	if node_count == 0 { return if root_index == -1 { i64(0) } else { i64(-1) } }
	if root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }
	root := usize(root_index)

	mut parent := [max_node_count]i64{init: -1}
	mut stack := [max_node_count]usize{}
	mut seen := [max_node_count]bool{}
	mut coin_total := i64(0)
	for node in 0 .. node_count {
		unsafe {
			value := nodes[3 * node]
			if value < 0 || value > 100 { return -1 }
			coin_total += value
			for edge in 1 .. 3 {
				child := nodes[3 * node + edge]
				if child < -1 || (child >= 0 && u64(child) >= u64(node_count)) { return -1 }
				if child >= 0 {
					child_index := usize(child)
					if parent[child_index] != -1 { return -1 }
					parent[child_index] = i64(node)
				}
			}
		}
	}
	if coin_total != i64(node_count) { return -1 }
	if parent[root] != -1 { return -1 }
	for node in 0 .. node_count {
		if node != root && parent[node] == -1 { return -1 }
	}

	mut top := usize(0)
	mut reached := usize(0)
	stack[top] = root
	top++
	for top > 0 {
		top--
		node := stack[top]
		if seen[node] { return -1 }
		seen[node] = true
		reached++
		unsafe {
			for edge in 1 .. 3 {
				child := nodes[3 * node + edge]
				if child >= 0 {
					stack[top] = usize(child)
					top++
				}
			}
		}
	}
	if reached != node_count { return -1 }

	mut moves := i64(0)
	_ = analyze(nodes, root_index, mut moves)
	return moves
}
