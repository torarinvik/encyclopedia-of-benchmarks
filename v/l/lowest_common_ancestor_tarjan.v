module lowest_common_ancestor_tarjan

const max_node_count = 256
const max_query_count = 1024
const max_adjacency_count = 2 * (max_node_count - 1)
const max_query_adjacency_count = 2 * max_query_count

fn find_root(mut parent []int, node int) int {
	mut root := node
	for parent[root] != root { root = parent[root] }
	mut current := node
	for parent[current] != current {
		next := parent[current]
		parent[current] = root
		current = next
	}
	return root
}

fn unite(mut parent []int, mut rank []int, left int, right int) {
	left_root := find_root(mut parent, left)
	right_root := find_root(mut parent, right)
	if left_root == right_root { return }
	if rank[left_root] < rank[right_root] { parent[left_root] = right_root }
	else if rank[left_root] > rank[right_root] { parent[right_root] = left_root }
	else {
		parent[right_root] = left_root
		rank[left_root]++
	}
}

@[export: 'lowest_common_ancestor_tarjan']
pub fn lowest_common_ancestor_tarjan(input &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if length < 4 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_node_count { return -1 }
		node_count := int(input[0])
		if input[1] < 0 || input[1] >= i64(node_count) || input[2] != i64(node_count - 1) ||
			input[3] < 0 || input[3] > max_query_count { return -1 }
			root := int(input[1])
			edge_count := int(input[2])
			query_count := int(input[3])
		if int(length) != 4 + 2 * edge_count + 2 * query_count { return -1 }
		mut validation_parent := []int{len: max_node_count}
		mut dsu_parent := []int{len: max_node_count}
		mut ancestor := []int{len: max_node_count}
		mut validation_rank := []int{len: max_node_count}
		mut dsu_rank := []int{len: max_node_count}
		mut edge_head := []i64{len: max_node_count}
		mut edge_to := []i64{len: max_adjacency_count}
		mut edge_next := []i64{len: max_adjacency_count}
		mut query_head := []i64{len: max_node_count}
		mut query_to := []i64{len: max_query_adjacency_count}
		mut query_next := []i64{len: max_query_adjacency_count}
		mut query_id := []i64{len: max_query_adjacency_count}
		mut answers := []i64{len: max_query_count}
		mut tree_parent := []i64{len: max_node_count}
		mut cursor := []i64{len: max_node_count}
		mut visited := []bool{len: max_node_count}
		mut finished := []bool{len: max_node_count}
		mut stack := []int{len: max_node_count}
		for node in 0 .. node_count {
			validation_parent[node] = node
			dsu_parent[node] = node
			ancestor[node] = node
			edge_head[node] = -1
			query_head[node] = -1
			tree_parent[node] = -1
		}
		for edge in 0 .. edge_count {
			left_arg := input[4 + 2 * edge]
			right_arg := input[5 + 2 * edge]
			if left_arg < 0 || right_arg < 0 || left_arg >= i64(node_count) ||
				right_arg >= i64(node_count) || left_arg == right_arg { return -1 }
			left := int(left_arg)
			right := int(right_arg)
			if find_root(mut validation_parent, left) == find_root(mut validation_parent, right) { return -1 }
			unite(mut validation_parent, mut validation_rank, left, right)
			forward := 2 * edge
			reverse := forward + 1
			edge_to[forward] = i64(right)
			edge_next[forward] = edge_head[left]
			edge_head[left] = i64(forward)
			edge_to[reverse] = i64(left)
			edge_next[reverse] = edge_head[right]
			edge_head[right] = i64(reverse)
		}
		root_component := find_root(mut validation_parent, root)
		for node in 0 .. node_count {
			if find_root(mut validation_parent, node) != root_component { return -1 }
		}
		for query in 0 .. query_count {
			left_arg := input[4 + 2 * edge_count + 2 * query]
			right_arg := input[5 + 2 * edge_count + 2 * query]
			if left_arg < 0 || right_arg < 0 || left_arg >= i64(node_count) || right_arg >= i64(node_count) { return -1 }
			left := int(left_arg)
			right := int(right_arg)
			first := 2 * query
			second := first + 1
			query_to[first] = i64(right)
			query_id[first] = i64(query)
			query_next[first] = query_head[left]
			query_head[left] = i64(first)
			query_to[second] = i64(left)
			query_id[second] = i64(query)
			query_next[second] = query_head[right]
			query_head[right] = i64(second)
		}
		if query_count > int(output_capacity) { return -2 }
		mut top := 1
		stack[0] = root
		visited[root] = true
		cursor[root] = edge_head[root]
		for top > 0 {
			node := stack[top - 1]
			edge := cursor[node]
			if edge >= 0 {
				cursor[node] = edge_next[int(edge)]
				child := int(edge_to[int(edge)])
				if child == int(tree_parent[node]) { continue }
				if visited[child] { return -1 }
				visited[child] = true
				tree_parent[child] = i64(node)
				cursor[child] = edge_head[child]
				stack[top] = child
				top++
				continue
			}
			finished[node] = true
			mut item := query_head[node]
			for item >= 0 {
				index := int(item)
				other := int(query_to[index])
				if finished[other] { answers[int(query_id[index])] = i64(ancestor[find_root(mut dsu_parent, other)]) }
				item = query_next[index]
			}
			top--
			if tree_parent[node] >= 0 {
				parent := int(tree_parent[node])
				unite(mut dsu_parent, mut dsu_rank, parent, node)
				component := find_root(mut dsu_parent, parent)
				ancestor[component] = parent
			}
		}
		for query in 0 .. query_count { output[query] = u8(answers[query]) }
		return i64(query_count)
	}
}
