module tree_matching

const max_nodes = 64
const max_input_values = 2 + 3 * (max_nodes - 1)
const matrix_size = max_nodes * max_nodes

fn matching_dp(node int, parent int, count int, adjacent &bool, weights &i64,
	visited &bool, parent_of &int, without_edge &i64, with_edge &i64, reached &int) {
	unsafe {
		visited[node] = true
		parent_of[node] = parent
		*reached += 1
		mut base := i64(0)
		for child in 0 .. count {
			if adjacent[node * max_nodes + child] && child != parent && !visited[child] {
				matching_dp(child, node, count, adjacent, weights, visited, parent_of,
					without_edge, with_edge, reached)
					base += max(without_edge[child], with_edge[child])
			}
		}
		without_edge[node] = base
		with_edge[node] = 0
		for child in 0 .. count {
			if parent_of[child] == node {
				child_best := max(without_edge[child], with_edge[child])
				candidate := base - child_best + without_edge[child] + weights[node * max_nodes + child]
				with_edge[node] = max(with_edge[node], candidate)
			}
		}
	}
}

@[export: 'tree_matching']
pub fn tree_matching(values &i64, length usize) i64 {
	if length < 2 || length > usize(max_input_values) { return -1 }
	unsafe {
		if values == nil { return -1 }
		if values[0] < 1 || values[0] > max_nodes { return -1 }
		count := int(values[0])
		if length != usize(2 + 3 * (count - 1)) || values[1] < 0 || values[1] >= count { return -1 }
		mut adjacent := [matrix_size]bool{}
		mut weights := [matrix_size]i64{}
		for edge in 0 .. count - 1 {
			a_value := values[2 + 3 * edge]
			b_value := values[3 + 3 * edge]
			weight := values[4 + 3 * edge]
			if a_value < 0 || b_value < 0 || a_value >= count || b_value >= count || a_value == b_value || weight < 0 || weight > 1000 { return -1 }
			a := int(a_value); b := int(b_value)
			ab := a * max_nodes + b; ba := b * max_nodes + a
			if adjacent[ab] { return -1 }
			adjacent[ab] = true; adjacent[ba] = true
			weights[ab] = weight; weights[ba] = weight
		}
		mut visited := [max_nodes]bool{}
		mut parent_of := [max_nodes]int{}
		for node in 0 .. max_nodes { parent_of[node] = -2 }
		mut without_edge := [max_nodes]i64{}
		mut with_edge := [max_nodes]i64{}
		mut reached := 0
		root := int(values[1])
		matching_dp(root, -1, count, &adjacent[0], &weights[0], &visited[0], &parent_of[0],
			&without_edge[0], &with_edge[0], &reached)
		if reached != count { return -1 }
		return max(without_edge[root], with_edge[root])
	}
}
