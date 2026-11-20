module kruskal_reconstruction_tree_bottleneck

const max_vertices = 8
const max_edges = 16
const max_nodes = max_vertices + max_edges
const log_levels = 5
const max_input_length = 67

struct Edge {
	from int
	to int
	weight i64
	original_index int
}

fn find_root(mut parent &int, start int) int {
	unsafe {
		mut root := start
		for parent[root] != root { root = parent[root] }
		mut vertex := start
		for parent[vertex] != vertex {
			next := parent[vertex]
			parent[vertex] = root
			vertex = next
		}
		return root
	}
}

fn edge_greater(left Edge, right Edge) bool {
	return left.weight > right.weight || (left.weight == right.weight && left.original_index > right.original_index)
}

@[export: 'kruskal_reconstruction_tree_bottleneck']
pub fn kruskal_reconstruction_tree_bottleneck(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > usize(max_input_length) { return -1 }
		n_value, m_value, q_value := input[0], input[1], input[2]
		if n_value < 1 || n_value > max_vertices || m_value < 0 || m_value > max_edges
			|| q_value < 1 || q_value > 8 { return -1 }
		n, m, q := int(n_value), int(m_value), int(q_value)
		query_offset := 3 + 3 * m
		if length != usize(query_offset + 2 * q) { return -1 }

		mut edges := [max_edges]Edge{}
		for edge_index in 0 .. m {
			from_value, to_value, weight := input[3 + 3 * edge_index], input[4 + 3 * edge_index], input[5 + 3 * edge_index]
			if from_value < 0 || from_value >= n_value || to_value < 0 || to_value >= n_value
				|| weight < 0 || weight > 1_000_000 { return -1 }
			edges[edge_index] = Edge{
				from: int(from_value)
				to: int(to_value)
				weight: weight
				original_index: edge_index
			}
		}
		for query in 0 .. q {
			for side in 0 .. 2 {
				vertex := input[query_offset + 2 * query + side]
				if vertex < 0 || vertex >= n_value { return -1 }
			}
		}

		for index in 1 .. m {
			edge := edges[index]
			mut position := index
			for position > 0 && edge_greater(edges[position - 1], edge) {
				edges[position] = edges[position - 1]
				position--
			}
			edges[position] = edge
		}

		mut dsu_parent := [max_vertices]int{}
		mut dsu_size := [max_vertices]int{}
		mut tree_root := [max_vertices]int{}
		for vertex in 0 .. n {
			dsu_parent[vertex] = vertex
			dsu_size[vertex] = 1
			tree_root[vertex] = vertex
		}
		mut tree_parent := [max_nodes]int{}
		mut children := [max_nodes * 2]int{}
		mut label := [max_nodes]i64{}
		for node in 0 .. max_nodes {
			tree_parent[node] = -1
			children[2 * node] = -1
			children[2 * node + 1] = -1
		}
		mut node_count := n
		for edge_index in 0 .. m {
			edge := edges[edge_index]
			mut left_root := find_root(mut dsu_parent[0], edge.from)
			mut right_root := find_root(mut dsu_parent[0], edge.to)
			if left_root == right_root { continue }
			merged_node := node_count
			node_count++
			children[2 * merged_node] = tree_root[left_root]
			children[2 * merged_node + 1] = tree_root[right_root]
			label[merged_node] = edge.weight
			tree_parent[tree_root[left_root]] = merged_node
			tree_parent[tree_root[right_root]] = merged_node
			if dsu_size[left_root] < dsu_size[right_root] { left_root, right_root = right_root, left_root }
			dsu_parent[right_root] = left_root
			dsu_size[left_root] += dsu_size[right_root]
			tree_root[left_root] = merged_node
		}

		mut depth := [max_nodes]int{}
		mut ancestors := [log_levels * max_nodes]int{}
		for root in 0 .. node_count {
			if tree_parent[root] >= 0 { continue }
			ancestors[root] = root
			mut stack := [max_nodes]int{}
			mut top := 1
			stack[0] = root
			for top > 0 {
				top--
				node := stack[top]
				for side in 0 .. 2 {
					child := children[2 * node + side]
					if child < 0 { continue }
					depth[child] = depth[node] + 1
					ancestors[child] = node
					stack[top] = child
					top++
				}
			}
		}
		for level in 1 .. log_levels {
			for node in 0 .. node_count {
				middle := ancestors[(level - 1) * max_nodes + node]
				ancestors[level * max_nodes + node] = ancestors[(level - 1) * max_nodes + middle]
			}
		}

		mut checksum := i64(0)
		for query in 0 .. q {
			source := int(input[query_offset + 2 * query])
			destination := int(input[query_offset + 2 * query + 1])
			mut answer := i64(0)
			if source == destination {
				answer = 0
			} else if find_root(mut dsu_parent[0], source) != find_root(mut dsu_parent[0], destination) {
				answer = -1
			} else {
				mut left, mut right := source, destination
				if depth[left] < depth[right] { left, right = right, left }
				difference := depth[left] - depth[right]
				for level in 0 .. log_levels {
					if difference & (1 << level) != 0 { left = ancestors[level * max_nodes + left] }
				}
				if left != right {
					for level := log_levels - 1; level >= 0; level-- {
						up_left := ancestors[level * max_nodes + left]
						up_right := ancestors[level * max_nodes + right]
						if up_left != up_right { left = up_left; right = up_right }
					}
					left = ancestors[left]
				}
				answer = label[left]
			}
			checksum += i64(query + 1) * (answer + 2)
		}
		return checksum
	}
}
