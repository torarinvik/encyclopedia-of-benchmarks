module pagoda_meldable_priority_queue

const max_queues = 8
const max_operations = 64
const max_parseable_words = usize(259)
const nil_node = i64(-1)

struct PagodaState {
mut:
	keys [max_operations]i64
	leftmost [max_operations]i64
	rightmost [max_operations]i64
	roots [max_queues]i64
	g_branch [max_operations]i64
	d_branch [max_operations]i64
}

fn p_branch_stack(root i64, right_branch bool, node_count int, mut state &PagodaState, use_g_stack bool) int {
	mut node := state.leftmost[int(root)]
	if right_branch { node = state.rightmost[int(root)] }
	if node < 0 || node >= i64(node_count) { return -1 }
	mut count := 0
	for count < node_count {
		if use_g_stack { state.g_branch[count] = node } else { state.d_branch[count] = node }
		count++
		if node == root { return count }
		if right_branch { node = state.rightmost[int(node)] } else { node = state.leftmost[int(node)] }
		if node < 0 || node >= i64(node_count) { return -1 }
	}
	return -1
}

fn p_meld(g_root i64, d_root i64, node_count int, mut state &PagodaState) i64 {
	if g_root < 0 { return d_root }
	if d_root < 0 { return g_root }
	g_count := p_branch_stack(g_root, true, node_count, mut state, true)
	d_count := p_branch_stack(d_root, false, node_count, mut state, false)
	if g_count < 1 || d_count < 1 { return -2 }
	mut gi := 0
	mut di := 0
	mut central := nil_node
	mut central_left := nil_node
	mut central_right := nil_node
	for gi < g_count || di < d_count {
		take_g := di >= d_count || (gi < g_count && state.keys[int(state.g_branch[gi])] > state.keys[int(state.d_branch[di])])
		mut node := i64(-1)
		mut kept := i64(-1)
		if take_g {
			node = state.g_branch[gi]
			gi++
			kept = state.leftmost[int(node)]
		} else {
			node = state.d_branch[di]
			di++
			kept = state.rightmost[int(node)]
		}
		if central >= 0 {
			if take_g {
				state.rightmost[int(central)] = node
				state.leftmost[int(central)] = central_left
				if central_left == central { state.leftmost[int(central)] = nil_node }
			} else {
				state.leftmost[int(central)] = node
				state.rightmost[int(central)] = central_right
				if central_right == central { state.rightmost[int(central)] = nil_node }
			}
		}
		mut new_left := i64(-1)
		mut new_right := i64(-1)
		if take_g {
			new_left = if kept < 0 { node } else { kept }
			new_right = if central >= 0 { central_right } else { node }
		} else {
			new_left = if central >= 0 { central_left } else { node }
			new_right = if kept < 0 { node } else { kept }
		}
		state.leftmost[int(node)] = new_left
		state.rightmost[int(node)] = new_right
		central = node
		central_left = new_left
		central_right = new_right
	}
	return central
}

fn p_extract_min(root i64, node_count int, mut state &PagodaState) i64 {
	old_left := state.leftmost[int(root)]
	old_right := state.rightmost[int(root)]
	mut left_child := nil_node
	mut right_child := nil_node
	if old_left != root {
		mut node := old_left
		mut steps := 0
		for node >= 0 && node < i64(node_count) && state.leftmost[int(node)] != root && steps < node_count {
			node = state.leftmost[int(node)]
			steps++
		}
		if node < 0 || node >= i64(node_count) || state.leftmost[int(node)] != root { return -2 }
		left_child = node
	}
	if old_right != root {
		mut node := old_right
		mut steps := 0
		for node >= 0 && node < i64(node_count) && state.rightmost[int(node)] != root && steps < node_count {
			node = state.rightmost[int(node)]
			steps++
		}
		if node < 0 || node >= i64(node_count) || state.rightmost[int(node)] != root { return -2 }
		right_child = node
	}
	if left_child >= 0 {
		state.leftmost[int(left_child)] = old_left
		if state.rightmost[int(left_child)] < 0 { state.rightmost[int(left_child)] = left_child }
	}
	if right_child >= 0 {
		state.rightmost[int(right_child)] = old_right
		if state.leftmost[int(right_child)] < 0 { state.leftmost[int(right_child)] = right_child }
	}
	new_root := p_meld(right_child, left_child, node_count, mut state)
	state.leftmost[int(root)] = nil_node
	state.rightmost[int(root)] = nil_node
	return new_root
}

pub fn pagoda_meldable_priority_queue(input &i64, length usize) i64 {
	if input == nil || length < 2 || length > max_parseable_words { return -1 }
	unsafe {
		queue_count := input[0]
		operation_count := input[1]
		if queue_count < 1 || queue_count > max_queues || operation_count < 0 || operation_count > max_operations || length != usize(2 + 4 * operation_count) || length > 258 { return -1 }
		mut state := PagodaState{}
		for i in 0 .. max_operations {
			state.leftmost[i] = nil_node
			state.rightmost[i] = nil_node
		}
		for i in 0 .. max_queues { state.roots[i] = nil_node }
		mut node_count := 0
		mut result := i64(0)
		for op in 0 .. int(operation_count) {
			offset := 2 + 4 * op
			opcode := input[offset]
			first := input[offset + 1]
			second := input[offset + 2]
			priority := input[offset + 3]
			if opcode == 1 {
				if first < 0 || first >= queue_count || second != 0 || priority < -1000 || priority > 1000 || node_count >= max_operations { return -1 }
				for i in 0 .. node_count { if state.keys[i] == priority { return -1 } }
				node := node_count
				node_count++
				state.keys[node] = priority
				state.leftmost[node] = i64(node)
				state.rightmost[node] = i64(node)
				current_root := state.roots[int(first)]
				merged := p_meld(current_root, i64(node), node_count, mut state)
				if merged < 0 { return -1 }
				state.roots[int(first)] = merged
			} else if opcode == 2 {
				if first < 0 || first >= queue_count || second < 0 || second >= queue_count || first == second || priority != 0 { return -1 }
				destination_root := state.roots[int(first)]
				source_root := state.roots[int(second)]
				merged := p_meld(destination_root, source_root, node_count, mut state)
				if merged == -2 { return -1 }
				state.roots[int(first)] = merged
				state.roots[int(second)] = nil_node
			} else if opcode == 3 || opcode == 4 {
				if first < 0 || first >= queue_count || second != 0 || priority != 0 || state.roots[int(first)] < 0 { return -1 }
				root := state.roots[int(first)]
				result += (i64(op) + 1) * (state.keys[int(root)] + 1001)
				if opcode == 4 {
					new_root := p_extract_min(root, node_count, mut state)
					if new_root == -2 { return -1 }
					state.roots[int(first)] = new_root
				}
			} else { return -1 }
		}
		return result
	}
}
