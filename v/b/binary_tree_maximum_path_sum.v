module binary_tree_maximum_path_sum

const max_node_count = 1023

struct GainResult {
	gain i64
	valid bool
}

fn maximum_gain(nodes &i64, node_count usize, node i64, best_path &i64) GainResult {
	if node == -1 { return GainResult{ gain: 0, valid: true } }
	if node < 0 || u64(node) >= u64(node_count) { return GainResult{ gain: 0, valid: false } }
	index := usize(node)
	unsafe {
		value := nodes[3 * index]
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		if value < -1000 || value > 1000 || left < -1 ||
			(left >= 0 && u64(left) >= u64(node_count)) || right < -1 ||
			(right >= 0 && u64(right) >= u64(node_count)) {
			return GainResult{ gain: 0, valid: false }
		}
		left_result := maximum_gain(nodes, node_count, left, best_path)
		if !left_result.valid { return GainResult{ gain: 0, valid: false } }
		right_result := maximum_gain(nodes, node_count, right, best_path)
		if !right_result.valid { return GainResult{ gain: 0, valid: false } }
		positive_left := if left_result.gain > 0 { left_result.gain } else { i64(0) }
		positive_right := if right_result.gain > 0 { right_result.gain } else { i64(0) }
		through_node := value + positive_left + positive_right
		if through_node > best_path[0] { best_path[0] = through_node }
		best_child_gain := if positive_left > positive_right { positive_left } else { positive_right }
		gain := value + best_child_gain
		return GainResult{ gain: gain, valid: true }
	}
}

@[export: 'binary_tree_maximum_path_sum']
pub fn binary_tree_maximum_path_sum(nodes &i64, node_count usize, root_index i64) i64 {
	if node_count == 0 || node_count > max_node_count || root_index < 0 ||
		u64(root_index) >= u64(node_count) { return -1 }
	mut best_path := i64(-2_147_483_648)
	result := unsafe { maximum_gain(nodes, node_count, root_index, &best_path) }
	if !result.valid { return -1 }
	return best_path
}
