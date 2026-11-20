@[export: 'schorr_waite_graph_marking']
pub fn schorr_waite_graph_marking(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 66 { return -1 }

		node_count_value := input[0]
		root := input[1]
		if node_count_value < 1 || node_count_value > 32 { return -1 }
		node_count := int(node_count_value)
		if length != usize(2 + 2 * node_count) || root < 0 || root >= node_count_value { return -1 }

		mut left := [32]i64{}
		mut right := [32]i64{}
		mut marked := [32]bool{}
		mut phase := [32]bool{}
		for node in 0 .. node_count {
			left_child := input[2 + 2 * node]
			right_child := input[3 + 2 * node]
			if left_child < -1 || left_child >= node_count_value || right_child < -1 || right_child >= node_count_value { return -1 }
			left[node] = left_child
			right[node] = right_child
		}

		mut parent := i64(-1)
		mut current := root
		mut temporary := i64(0)
		for parent != -1 || (current != -1 && !marked[int(current)]) {
			if current == -1 || marked[int(current)] {
				frame := int(parent)
				if phase[frame] {
					temporary = current
					current = parent
					parent = right[frame]
					right[frame] = temporary
				} else {
					temporary = current
					current = right[frame]
					right[frame] = left[frame]
					left[frame] = temporary
					phase[frame] = true
				}
			} else {
				temporary = parent
				parent = current
				current = left[int(parent)]
				left[int(parent)] = temporary
				marked[int(parent)] = true
				phase[int(parent)] = false
			}
		}

		mut reachable := i64(0)
		for node in 0 .. node_count {
			if marked[node] { reachable |= i64(1) << node }
		}
		return reachable
	}
}
