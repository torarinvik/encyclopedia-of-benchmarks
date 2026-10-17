package lcabinary_lifting

import "core:c"

MAX_NODES :: 128
MAX_QUERIES :: 256
MAX_LEVELS :: 7
MAX_VALID_INPUT_LENGTH :: c.size_t(770)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(771)

lca :: proc "contextless" (left_arg, right_arg: int, depth: [^]int, up: [^][MAX_LEVELS]int, levels: int) -> int {
	left, right := left_arg, right_arg
	if depth[left] < depth[right] { left, right = right, left }
	difference := depth[left]-depth[right]
	bit := 0
	for difference > 0 {
		if difference&1 != 0 { left = up[left][bit] }
		difference >>= 1
		bit += 1
	}
	if left == right do return left
	for level := levels-1; level >= 0; level -= 1 {
		if up[left][level] != up[right][level] { left, right = up[left][level], up[right][level] }
	}
	return up[left][0]
}

lca_binary_lifting_benchmark :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input[0] < 2 || input[0] > MAX_NODES do return -1
	node_count := int(input[0])
	if input[1] < 0 || input[1] >= i64(node_count) do return -1
	root := int(input[1])
	if input[2] != i64(node_count-1) do return -1
	edge_count := node_count-1
	query_count_index := 3+2*edge_count
	if c.size_t(query_count_index) >= length do return -1
	query_value := input[query_count_index]
	if query_value < 0 || query_value > MAX_QUERIES do return -1
	query_count := int(query_value)
	if length != c.size_t(query_count_index+1+2*query_count) || length > MAX_VALID_INPUT_LENGTH do return -1

	var adjacency: [MAX_NODES][MAX_NODES]bool
	for edge in 0 ..< edge_count {
		left_value, right_value := input[3+2*edge], input[4+2*edge]
		if left_value < 0 || left_value >= i64(node_count) || right_value < 0 || right_value >= i64(node_count) || left_value == right_value do return -1
		left, right := int(left_value), int(right_value)
		if adjacency[left][right] do return -1
		adjacency[left][right], adjacency[right][left] = true, true
	}

	var parent: [MAX_NODES]int
	var depth: [MAX_NODES]int
	var visited: [MAX_NODES]bool
	var queue: [MAX_NODES]int
	head, tail := 0, 1
	queue[0] = root
	visited[root] = true
	parent[root] = root
	for head < tail {
		node := queue[head]
		head += 1
		for child in 0 ..< node_count {
			if !adjacency[node][child] do continue
			if !visited[child] {
				visited[child] = true
				parent[child] = node
				depth[child] = depth[node]+1
				queue[tail] = child
				tail += 1
			} else if child != parent[node] { return -1 }
		}
	}
	if tail != node_count do return -1

	levels := 1
	for (1 << levels) < node_count { levels += 1 }
	var up: [MAX_NODES][MAX_LEVELS]int
	for node in 0 ..< node_count { up[node][0] = parent[node] }
	for level in 1 ..< levels { for node in 0 ..< node_count { up[node][level] = up[up[node][level-1]][level-1] } }

	checksum := i64(0)
	queries_start := query_count_index+1
	for query in 0 ..< query_count {
		left_value, right_value := input[queries_start+2*query], input[queries_start+2*query+1]
		if left_value < 0 || left_value >= i64(node_count) || right_value < 0 || right_value >= i64(node_count) do return -1
		ancestor := lca(int(left_value), int(right_value), &depth[0], &up[0], levels)
		checksum += i64(query+1)*i64(ancestor+1)
	}
	return checksum
}
