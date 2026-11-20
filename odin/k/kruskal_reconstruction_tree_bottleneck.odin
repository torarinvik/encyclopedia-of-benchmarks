package kruskal_reconstruction_tree_bottleneck

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 16
MAX_NODES :: MAX_VERTICES + MAX_EDGES
LOG_LEVELS :: 5
MAX_INPUT_LENGTH :: 67

Edge :: struct { from_vertex: int, to_vertex: int, weight: i64, original_index: int }

find_root :: proc(parent: ^[MAX_VERTICES]int, start: int) -> int {
	root := start
	for parent[root] != root { root = parent[root] }
	vertex := start
	for parent[vertex] != vertex {
		next := parent[vertex]
		parent[vertex] = root
		vertex = next
	}
	return root
}

edge_greater :: proc(left, right: Edge) -> bool {
	return left.weight > right.weight || (left.weight == right.weight && left.original_index > right.original_index)
}

@(export)
kruskal_reconstruction_tree_bottleneck :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	n_value, m_value, q_value := input[0], input[1], input[2]
	if n_value < 1 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES
		|| q_value < 1 || q_value > 8 do return -1
	n, m, q := int(n_value), int(m_value), int(q_value)
	query_offset := 3 + 3*m
	if int(length) != query_offset + 2*q do return -1

	var edges: [MAX_EDGES]Edge
	for edge_index := 0; edge_index < m; edge_index += 1 {
		from_value, to_value, weight := input[3+3*edge_index], input[4+3*edge_index], input[5+3*edge_index]
		if from_value < 0 || from_value >= n_value || to_value < 0 || to_value >= n_value
			|| weight < 0 || weight > 1_000_000 do return -1
		edges[edge_index] = Edge{from_vertex = int(from_value), to_vertex = int(to_value),
			weight = weight, original_index = edge_index}
	}
	for query := 0; query < q; query += 1 {
		for side := 0; side < 2; side += 1 {
			vertex := input[query_offset+2*query+side]
			if vertex < 0 || vertex >= n_value do return -1
		}
	}

	for index := 1; index < m; index += 1 {
		edge := edges[index]
		position := index
		for position > 0 && edge_greater(edges[position-1], edge) {
			edges[position] = edges[position-1]
			position -= 1
		}
		edges[position] = edge
	}

	var dsu_parent: [MAX_VERTICES]int
	var dsu_size: [MAX_VERTICES]int
	var tree_root: [MAX_VERTICES]int
	for vertex := 0; vertex < n; vertex += 1 {
		dsu_parent[vertex] = vertex
		dsu_size[vertex] = 1
		tree_root[vertex] = vertex
	}
	var tree_parent: [MAX_NODES]int
	var children: [MAX_NODES][2]int
	var label: [MAX_NODES]i64
	for node := 0; node < MAX_NODES; node += 1 {
		tree_parent[node] = -1
		children[node] = [2]int{-1, -1}
	}
	node_count := n
	for edge_index := 0; edge_index < m; edge_index += 1 {
		edge := edges[edge_index]
		left_root := find_root(&dsu_parent, edge.from_vertex)
		right_root := find_root(&dsu_parent, edge.to_vertex)
		if left_root == right_root do continue
		merged_node := node_count
		node_count += 1
		children[merged_node] = [2]int{tree_root[left_root], tree_root[right_root]}
		label[merged_node] = edge.weight
		tree_parent[tree_root[left_root]] = merged_node
		tree_parent[tree_root[right_root]] = merged_node
		if dsu_size[left_root] < dsu_size[right_root] { left_root, right_root = right_root, left_root }
		dsu_parent[right_root] = left_root
		dsu_size[left_root] += dsu_size[right_root]
		tree_root[left_root] = merged_node
	}

	var depth: [MAX_NODES]int
	var ancestors: [LOG_LEVELS][MAX_NODES]int
	for root := 0; root < node_count; root += 1 {
		if tree_parent[root] >= 0 do continue
		ancestors[0][root] = root
		var stack: [MAX_NODES]int
		top := 1
		stack[0] = root
		for top > 0 {
			top -= 1
			node := stack[top]
			for side := 0; side < 2; side += 1 {
				child := children[node][side]
				if child < 0 do continue
				depth[child] = depth[node] + 1
				ancestors[0][child] = node
				stack[top] = child
				top += 1
			}
		}
	}
	for level := 1; level < LOG_LEVELS; level += 1 {
		for node := 0; node < node_count; node += 1 {
			ancestors[level][node] = ancestors[level-1][ancestors[level-1][node]]
		}
	}

	checksum := i64(0)
	for query := 0; query < q; query += 1 {
		source := int(input[query_offset+2*query])
		destination := int(input[query_offset+2*query+1])
		answer := i64(0)
		if source == destination {
			answer = 0
		} else if find_root(&dsu_parent, source) != find_root(&dsu_parent, destination) {
			answer = -1
		} else {
			left, right := source, destination
			if depth[left] < depth[right] { left, right = right, left }
			difference := depth[left] - depth[right]
			for level := 0; level < LOG_LEVELS; level += 1 {
				if difference & (1 << level) != 0 { left = ancestors[level][left] }
			}
			if left != right {
				for level := LOG_LEVELS-1; level >= 0; level -= 1 {
					if ancestors[level][left] != ancestors[level][right] {
						left = ancestors[level][left]
						right = ancestors[level][right]
					}
				}
				left = ancestors[0][left]
			}
			answer = label[left]
		}
		checksum += i64(query+1) * (answer + 2)
	}
	return checksum
}
