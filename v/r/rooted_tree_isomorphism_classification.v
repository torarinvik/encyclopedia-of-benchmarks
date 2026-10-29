module rooted_tree_isomorphism_classification

const (
	max_trees = 16
	max_tree_vertices = 32
	max_total_vertices = 128
	max_input_length = 1 + 2 * max_trees * max_tree_vertices
)

struct TreeSignature {
	child_count int
	child_types [max_tree_vertices]int
}

fn intern_signature(mut signatures [max_total_vertices]TreeSignature,
	mut signature_count int, children [max_tree_vertices]int, child_count int) int {
	for signature := 0; signature < signature_count; signature++ {
		if signatures[signature].child_count != child_count { continue }
		mut index := 0
		for index < child_count && signatures[signature].child_types[index] == children[index] {
			index++
		}
		if index == child_count { return signature }
	}
	if signature_count >= max_total_vertices { return max_total_vertices }
	result := signature_count
	signature_count++
	signatures[result].child_count = child_count
	for index := 0; index < child_count; index++ {
		signatures[result].child_types[index] = children[index]
	}
	return result
}

fn canonical_root_type(adjacency &[max_tree_vertices]u32, n int, root int,
	mut signatures [max_total_vertices]TreeSignature, mut signature_count int) int {
	mut parent := [max_tree_vertices]int{}
	mut order := [max_tree_vertices]int{}
	mut stack := [max_tree_vertices]int{}
	mut node_type := [max_tree_vertices]int{}
	mut visited := [max_tree_vertices]bool{}
	for vertex := 0; vertex < n; vertex++ { parent[vertex] = max_tree_vertices }
	parent[root] = root
	visited[root] = true
	mut stack_size, mut order_size := 1, 0
	stack[0] = root
	for stack_size > 0 {
		stack_size--
		vertex := stack[stack_size]
		order[order_size] = vertex
		order_size++
		for neighbor := 0; neighbor < n; neighbor++ {
			bit := u32(1) << u32(neighbor)
			if (adjacency[vertex] & bit) == 0 || neighbor == parent[vertex] { continue }
			if visited[neighbor] { return -1 }
			visited[neighbor] = true
			parent[neighbor] = vertex
			stack[stack_size] = neighbor
			stack_size++
		}
	}
	if order_size != n { return -1 }
	mut reverse := order_size
	for reverse > 0 {
		reverse--
		vertex := order[reverse]
		mut children := [max_tree_vertices]int{}
		mut child_count := 0
		for candidate := 0; candidate < n; candidate++ {
			if candidate != vertex && parent[candidate] == vertex {
				children[child_count] = node_type[candidate]
				child_count++
			}
		}
		for index := 1; index < child_count; index++ {
			value := children[index]
			mut place := index
			for place > 0 && children[place - 1] > value {
				children[place] = children[place - 1]
				place--
			}
			children[place] = value
		}
		node_type[vertex] = intern_signature(mut signatures, mut signature_count, children, child_count)
		if node_type[vertex] >= max_total_vertices { return -1 }
	}
	return node_type[root]
}

@[export: 'rooted_tree_isomorphism_classification']
pub fn rooted_tree_isomorphism_classification(values &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > usize(max_input_length) { return -1 }
		if values[0] < 1 || values[0] > max_trees { return -1 }
		tree_count := int(values[0])
		mut signatures := [max_total_vertices]TreeSignature{}
		mut signature_count := 0
		mut root_types := [max_trees]int{}
		mut labels := [max_trees]u8{}
		mut position, mut total_vertices, mut class_count := 1, 0, 0
		for tree := 0; tree < tree_count; tree++ {
			if position + 2 > int(length) { return -1 }
			n_value, root_value := values[position], values[position + 1]
			position += 2
			if n_value < 1 || n_value > max_tree_vertices || root_value < 0 || root_value >= n_value { return -1 }
			n := int(n_value)
			total_vertices += n
			if total_vertices > max_total_vertices { return -1 }
			edge_count := n - 1
			if position + 2 * edge_count > int(length) { return -1 }
			mut adjacency := [max_tree_vertices]u32{}
			for _ in 0 .. edge_count {
				left_value, right_value := values[position], values[position + 1]
				position += 2
				if left_value < 0 || right_value < 0 || left_value >= n_value || right_value >= n_value || left_value == right_value { return -1 }
				left, right := int(left_value), int(right_value)
				left_bit, right_bit := u32(1) << u32(left), u32(1) << u32(right)
				if (adjacency[left] & right_bit) != 0 { return -1 }
				adjacency[left] |= right_bit
				adjacency[right] |= left_bit
			}
			root_type := canonical_root_type(&adjacency, n, int(root_value), mut signatures, mut signature_count)
			if root_type < 0 { return -1 }
			root_types[tree] = root_type
			mut prior := 0
			for prior < tree && root_types[prior] != root_type { prior++ }
			if prior < tree { labels[tree] = labels[prior] }
			else {
				labels[tree] = u8(class_count)
				class_count++
			}
		}
		if position != int(length) { return -1 }
		if output == nil || output_capacity < usize(tree_count) { return -2 }
		for tree := 0; tree < tree_count; tree++ { output[tree] = labels[tree] }
		return i64(tree_count)
	}
}
