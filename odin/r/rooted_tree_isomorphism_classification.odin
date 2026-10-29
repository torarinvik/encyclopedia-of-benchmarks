package rooted_tree_isomorphism_classification

import "core:c"

Max_Trees :: 16
Max_Tree_Vertices :: 32
Max_Total_Vertices :: 128
Max_Input_Length :: 1 + 2 * Max_Trees * Max_Tree_Vertices

Signature :: struct {
	child_count: int,
	child_types: [Max_Tree_Vertices]int,
}

intern_signature :: proc "contextless" (signatures: [^]Signature, signature_count: ^int,
		children: [^]int, child_count: int) -> int {
	for signature := 0; signature < signature_count^; signature += 1 {
		if signatures[signature].child_count != child_count do continue
		index := 0
		for index < child_count && signatures[signature].child_types[index] == children[index] {
			index += 1
		}
		if index == child_count do return signature
	}
	if signature_count^ >= Max_Total_Vertices do return Max_Total_Vertices
	result := signature_count^
	signatures[result].child_count = child_count
	for index := 0; index < child_count; index += 1 {
		signatures[result].child_types[index] = children[index]
	}
	signature_count^ += 1
	return result
}

canonical_root_type :: proc "contextless" (adjacency: [^]u32, n, root: int,
		signatures: [^]Signature, signature_count: ^int) -> int {
	parent: [Max_Tree_Vertices]int = {}
	order: [Max_Tree_Vertices]int = {}
	stack: [Max_Tree_Vertices]int = {}
	node_type: [Max_Tree_Vertices]int = {}
	visited: [Max_Tree_Vertices]bool = {}
	for vertex := 0; vertex < n; vertex += 1 do parent[vertex] = Max_Tree_Vertices
	parent[root] = root
	visited[root] = true
	stack_size, order_size := 1, 0
	stack[0] = root
	for stack_size > 0 {
		stack_size -= 1
		vertex := stack[stack_size]
		order[order_size] = vertex
		order_size += 1
		for neighbor := 0; neighbor < n; neighbor += 1 {
			bit := u32(1) << u32(neighbor)
			if adjacency[vertex]&bit == 0 || neighbor == parent[vertex] do continue
			if visited[neighbor] do return -1
			visited[neighbor] = true
			parent[neighbor] = vertex
			stack[stack_size] = neighbor
			stack_size += 1
		}
	}
	if order_size != n do return -1

	reverse := order_size
	for reverse > 0 {
		reverse -= 1
		vertex := order[reverse]
		children: [Max_Tree_Vertices]int = {}
		child_count := 0
		for candidate := 0; candidate < n; candidate += 1 {
			if candidate != vertex && parent[candidate] == vertex {
				children[child_count] = node_type[candidate]
				child_count += 1
			}
		}
		for index := 1; index < child_count; index += 1 {
			value := children[index]
			place := index
			for place > 0 && children[place-1] > value {
				children[place] = children[place-1]
				place -= 1
			}
			children[place] = value
		}
		node_type[vertex] = intern_signature(signatures, signature_count, &children[0], child_count)
		if node_type[vertex] >= Max_Total_Vertices do return -1
	}
	return node_type[root]
}

@(export)
rooted_tree_isomorphism_classification :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(Max_Input_Length) do return -1
	if input[0] < 1 || input[0] > Max_Trees do return -1
	tree_count := int(input[0])
	signatures: [Max_Total_Vertices]Signature = {}
	signature_count := 0
	root_types: [Max_Trees]int = {}
	labels: [Max_Trees]u8 = {}
	position, total_vertices, class_count := 1, 0, 0
	for tree := 0; tree < tree_count; tree += 1 {
		if c.size_t(position + 2) > length do return -1
		n64, root64 := input[position], input[position+1]
		position += 2
		if n64 < 1 || n64 > Max_Tree_Vertices || root64 < 0 || root64 >= n64 do return -1
		n := int(n64)
		total_vertices += n
		if total_vertices > Max_Total_Vertices do return -1
		edge_count := n - 1
		if c.size_t(position + 2*edge_count) > length do return -1
		adjacency: [Max_Tree_Vertices]u32 = {}
		for edge := 0; edge < edge_count; edge += 1 {
			left64, right64 := input[position], input[position+1]
			position += 2
			if left64 < 0 || right64 < 0 || left64 >= n64 || right64 >= n64 || left64 == right64 do return -1
			left, right := int(left64), int(right64)
			left_bit, right_bit := u32(1) << u32(left), u32(1) << u32(right)
			if adjacency[left]&right_bit != 0 do return -1
			adjacency[left] |= right_bit
			adjacency[right] |= left_bit
		}
		root_type := canonical_root_type(&adjacency[0], n, int(root64), &signatures[0], &signature_count)
		if root_type < 0 do return -1
		root_types[tree] = root_type
		prior := 0
		for prior < tree && root_types[prior] != root_type do prior += 1
		if prior < tree do labels[tree] = labels[prior]
		else { labels[tree] = u8(class_count); class_count += 1 }
	}
	if c.size_t(position) != length do return -1
	if output == nil || output_capacity < c.size_t(tree_count) do return -2
	for tree := 0; tree < tree_count; tree += 1 do output[tree] = labels[tree]
	return i64(tree_count)
}
