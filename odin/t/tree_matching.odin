package tree_matching

MAX_NODES :: 64
MAX_INPUT_VALUES :: 2 + 3 * (MAX_NODES - 1)
MATRIX_SIZE :: MAX_NODES * MAX_NODES

matching_dp :: proc "contextless" (node, parent, count: int, adjacent: [^]bool,
		weights: [^]i64, visited: [^]bool, parent_of: [^]int,
		without_edge, with_edge: [^]i64, reached: ^int) {
	visited[node] = true
	parent_of[node] = parent
	reached^ += 1
	base: i64 = 0
	for child := 0; child < count; child += 1 {
		if adjacent[node * MAX_NODES + child] && child != parent && !visited[child] {
			matching_dp(child, node, count, adjacent, weights, visited, parent_of,
				without_edge, with_edge, reached)
				base += max(without_edge[child], with_edge[child])
		}
	}
	without_edge[node] = base
	with_edge[node] = 0
	for child := 0; child < count; child += 1 {
		if parent_of[child] == node {
			child_best := max(without_edge[child], with_edge[child])
			candidate := base - child_best + without_edge[child] + weights[node * MAX_NODES + child]
			with_edge[node] = max(with_edge[node], candidate)
		}
	}
}

@(export)
tree_matching :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > MAX_INPUT_VALUES || values[0] < 1 || values[0] > MAX_NODES do return -1
	count := int(values[0])
	if int(length) != 2 + 3 * (count - 1) || values[1] < 0 || values[1] >= i64(count) do return -1
	adjacent: [MATRIX_SIZE]bool
	weights: [MATRIX_SIZE]i64
	for edge := 0; edge < count - 1; edge += 1 {
		a_value, b_value, weight := values[2 + 3 * edge], values[3 + 3 * edge], values[4 + 3 * edge]
		if a_value < 0 || b_value < 0 || a_value >= i64(count) || b_value >= i64(count) || a_value == b_value || weight < 0 || weight > 1000 do return -1
		a, b := int(a_value), int(b_value)
		ab, ba := a * MAX_NODES + b, b * MAX_NODES + a
		if adjacent[ab] do return -1
		adjacent[ab], adjacent[ba] = true, true
		weights[ab], weights[ba] = weight, weight
	}
	visited: [MAX_NODES]bool
	parent_of: [MAX_NODES]int
	for node := 0; node < MAX_NODES; node += 1 do parent_of[node] = -2
	without_edge, with_edge: [MAX_NODES]i64
	reached := 0
	root := int(values[1])
	matching_dp(root, -1, count, &adjacent[0], &weights[0], &visited[0], &parent_of[0],
		&without_edge[0], &with_edge[0], &reached)
	if reached != count do return -1
	return max(without_edge[root], with_edge[root])
}
