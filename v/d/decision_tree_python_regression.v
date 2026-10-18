import math

const max_queries = 12
const max_tree_nodes = 23

struct RegressionTreeNode {
	prediction f64
	boundary  f64
	left      int
	right     int
	is_leaf   bool
}

fn regression_mean_y(input &f64, samples int, start int, count int) f64 {
	unsafe {
		mut total := 0.0
		for i in 0 .. count { total += input[3 + samples + start + i] }
		return total / f64(count)
	}
}

fn regression_feature_mse(input &f64, start int, count int, prediction f64) f64 {
	unsafe {
		mut total := 0.0
		for i in 0 .. count {
			difference := input[3 + start + i] - prediction
			total += difference * difference
		}
		return total / f64(count)
	}
}

fn regression_build_tree(input &f64, samples int, start int, count int, depth int, min_leaf int,
	mut nodes &RegressionTreeNode, mut next_node &int) int {
	unsafe {
		node := next_node[0]
		next_node[0]++
	total_mean := regression_mean_y(input, samples, start, count)
	if count < 2 * min_leaf || depth == 1 {
		nodes[node].prediction = total_mean
		nodes[node].is_leaf = true
		return node
	}
	mut best_split := 0
	mut minimum_error := 2.0 * regression_feature_mse(input, start, count, total_mean)
	for split in min_leaf .. count - min_leaf + 1 {
		left_mean := regression_mean_y(input, samples, start, split)
		right_count := count - split
		right_mean := regression_mean_y(input, samples, start + split, right_count)
		error := regression_feature_mse(input, start, split, left_mean) + regression_feature_mse(input, start + split, right_count, right_mean)
		if error < minimum_error {
			best_split = split
			minimum_error = error
		}
	}
	if best_split == 0 {
		nodes[node].prediction = total_mean
		nodes[node].is_leaf = true
		return node
	}
	boundary := input[3 + start + best_split]
	nodes[node].boundary = boundary
	nodes[node].is_leaf = false
	nodes[node].left = regression_build_tree(input, samples, start, best_split, depth - 1, min_leaf, mut nodes, mut next_node)
	nodes[node].right = regression_build_tree(input, samples, start + best_split, count - best_split, depth - 1, min_leaf, mut nodes, mut next_node)
	return node
	}
}

fn regression_predict_tree(nodes &RegressionTreeNode, root int, query f64) f64 {
	unsafe {
		mut node := root
		for !nodes[node].is_leaf {
			if query >= nodes[node].boundary { node = nodes[node].right } else { node = nodes[node].left }
		}
		return nodes[node].prediction
	}
}

@[export: 'decision_tree_python_regression']
pub fn decision_tree_python_regression(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 8 || input_length > 41 { return -1 }
		for i in 0 .. 3 {
			if !input[i].is_finite() || math.floor(input[i]) != input[i] { return -1 }
		}
		if input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 6 || input[2] < 2 || input[2] > 12 { return -1 }
		depth, min_leaf, samples := int(input[0]), int(input[1]), int(input[2])
		query_count_index := 3 + 2 * samples
		if input_length <= usize(query_count_index) { return -1 }
		query_value := input[query_count_index]
		if !query_value.is_finite() || math.floor(query_value) != query_value || query_value < 1 || query_value > 12 { return -1 }
		queries := int(query_value)
		if input_length != usize(query_count_index + 1 + queries) || input_length > 40 { return -1 }
		for i in 3 .. query_count_index {
			if !input[i].is_finite() || math.floor(input[i]) != input[i] || math.abs(input[i]) > 8 { return -1 }
		}
		for i in query_count_index + 1 .. int(input_length) {
			if !input[i].is_finite() || math.floor(input[i]) != input[i] || math.abs(input[i]) > 8 { return -1 }
		}
		mut tree := [max_tree_nodes]RegressionTreeNode{}
		mut next_node := 0
		root := regression_build_tree(input, samples, 0, samples, depth, min_leaf, mut tree[0], mut next_node)
		mut staged := [max_queries + 1]f64{}
		staged[0] = f64(queries)
		for i in 0 .. queries { staged[i + 1] = regression_predict_tree(tree[0], root, input[query_count_index + 1 + i]) }
		if output == nil || output_capacity < usize(queries + 1) { return -2 }
		for i in 0 .. queries + 1 { output[i] = staged[i] }
		return i64(queries + 1)
	}
}
