module lcabinary_lifting

const max_nodes = 128
const max_queries = 256
const max_levels = 7
const max_valid_input_length = 770
const max_parseable_input_length = 771

fn lowest_common_ancestor(left_arg int, right_arg int, depth []int, up [][max_levels]int, levels int) int {
	mut left, mut right := left_arg, right_arg
	if depth[left] < depth[right] { left, right = right, left }
	mut difference := depth[left] - depth[right]
	mut bit := 0
	for difference > 0 {
		if (difference & 1) != 0 { left = up[left][bit] }
		difference >>= 1
		bit++
	}
	if left == right { return left }
	mut level := levels - 1
	for level >= 0 {
		if up[left][level] != up[right][level] { left, right = up[left][level], up[right][level] }
		level--
	}
	return up[left][0]
}

@[export: 'lca_binary_lifting_benchmark']
pub fn lca_binary_lifting_benchmark(input &i64, length usize) i64 {
	if unsafe { input == nil } { return -1 }
	if length < 4 || length > usize(max_parseable_input_length) { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > max_nodes { return -1 }
		node_count := int(input[0])
		if input[1] < 0 || input[1] >= i64(node_count) || input[2] != i64(node_count - 1) { return -1 }
		root := int(input[1])
		edge_count := node_count - 1
		query_count_index := 3 + 2 * edge_count
		if usize(query_count_index) >= length { return -1 }
		query_value := input[query_count_index]
		if query_value < 0 || query_value > max_queries { return -1 }
		query_count := int(query_value)
		if length != usize(query_count_index + 1 + 2 * query_count) || length > usize(max_valid_input_length) { return -1 }

		mut adjacency := [max_nodes][max_nodes]bool{}
		for edge in 0 .. edge_count {
			left_value, right_value := input[3 + 2 * edge], input[4 + 2 * edge]
			if left_value < 0 || left_value >= i64(node_count) || right_value < 0 || right_value >= i64(node_count) || left_value == right_value { return -1 }
			left, right := int(left_value), int(right_value)
			if adjacency[left][right] { return -1 }
			adjacency[left][right], adjacency[right][left] = true, true
		}
		mut parent := [max_nodes]int{}
		mut depth := [max_nodes]int{}
		mut visited := [max_nodes]bool{}
		mut queue := [max_nodes]int{}
		mut head, mut tail := 0, 1
		queue[0] = root
		visited[root] = true
		parent[root] = root
		for head < tail {
			node := queue[head]
			head++
			for child in 0 .. node_count {
				if !adjacency[node][child] { continue }
				if !visited[child] {
					visited[child] = true
					parent[child] = node
					depth[child] = depth[node] + 1
					queue[tail] = child
					tail++
				} else if child != parent[node] { return -1 }
			}
		}
		if tail != node_count { return -1 }
		mut levels := 1
		for (1 << levels) < node_count { levels++ }
		mut up := [max_nodes][max_levels]int{}
		for node in 0 .. node_count { up[node][0] = parent[node] }
		for level in 1 .. levels { for node in 0 .. node_count { up[node][level] = up[up[node][level - 1]][level - 1] } }
		mut checksum := i64(0)
		queries_start := query_count_index + 1
		for query in 0 .. query_count {
			left_value, right_value := input[queries_start + 2 * query], input[queries_start + 2 * query + 1]
			if left_value < 0 || left_value >= i64(node_count) || right_value < 0 || right_value >= i64(node_count) { return -1 }
			ancestor := lowest_common_ancestor(int(left_value), int(right_value), depth[..], up[..], levels)
			checksum += i64(query + 1) * i64(ancestor + 1)
		}
		return checksum
	}
}
