module avltree_unique_key_ops

const max_nodes = 128
const max_ops = 128

struct AvlNode {
	mut:
		key i64
		left int
		right int
		height int
}

fn node_height(nodes &AvlNode, index int) int {
	if index < 0 { return 0 }
	unsafe { return nodes[index].height }
}
fn update_height(nodes &AvlNode, index int) {
	unsafe { nodes[index].height = 1 + max(node_height(nodes, nodes[index].left), node_height(nodes, nodes[index].right)) }
}
fn rotate_right(nodes &AvlNode, root int) int {
	unsafe {
		pivot := nodes[root].left
		middle := nodes[pivot].right
		nodes[pivot].right = root
		nodes[root].left = middle
		update_height(nodes, root)
		update_height(nodes, pivot)
		return pivot
	}
}
fn rotate_left(nodes &AvlNode, root int) int {
	unsafe {
		pivot := nodes[root].right
		middle := nodes[pivot].left
		nodes[pivot].left = root
		nodes[root].right = middle
		update_height(nodes, root)
		update_height(nodes, pivot)
		return pivot
	}
}
fn rebalance(nodes &AvlNode, root int) int {
	if root < 0 { return root }
	unsafe {
		update_height(nodes, root)
		balance := node_height(nodes, nodes[root].left) - node_height(nodes, nodes[root].right)
		if balance > 1 {
			left := nodes[root].left
			if node_height(nodes, nodes[left].right) > node_height(nodes, nodes[left].left) {
				nodes[root].left = rotate_left(nodes, left)
			}
			return rotate_right(nodes, root)
		}
		if balance < -1 {
			right := nodes[root].right
			if node_height(nodes, nodes[right].left) > node_height(nodes, nodes[right].right) {
				nodes[root].right = rotate_right(nodes, right)
			}
			return rotate_left(nodes, root)
		}
		return root
	}
}
fn insert_node(nodes &AvlNode, root int, key i64, next &int) int {
	unsafe {
		if root < 0 {
			index := next
			next++
			nodes[index] = AvlNode{key: key, left: -1, right: -1, height: 1}
			return index
		}
		if key < nodes[root].key { nodes[root].left = insert_node(nodes, nodes[root].left, key, next) }
		else { nodes[root].right = insert_node(nodes, nodes[root].right, key, next) }
		return rebalance(nodes, root)
	}
}
fn contains(nodes &AvlNode, root_input int, key i64) bool {
	mut root := root_input
	unsafe {
		for root >= 0 {
			if nodes[root].key == key { return true }
			root = if key < nodes[root].key { nodes[root].left } else { nodes[root].right }
		}
	}
	return false
}
fn maximum_node(nodes &AvlNode, root_input int) int {
	mut root := root_input
	unsafe { for nodes[root].right >= 0 { root = nodes[root].right } }
	return root
}
fn delete_node(nodes &AvlNode, root int, key i64) int {
	unsafe {
		if key < nodes[root].key { nodes[root].left = delete_node(nodes, nodes[root].left, key) }
		else if key > nodes[root].key { nodes[root].right = delete_node(nodes, nodes[root].right, key) }
		else {
			if nodes[root].left < 0 { return nodes[root].right }
			if nodes[root].right < 0 { return nodes[root].left }
			predecessor := maximum_node(nodes, nodes[root].left)
			nodes[root].key = nodes[predecessor].key
			nodes[root].left = delete_node(nodes, nodes[root].left, nodes[predecessor].key)
		}
		return rebalance(nodes, root)
	}
}
fn put_i64(output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) } }
}

@[export: 'avltree_unique_key_ops']
pub fn avltree_unique_key_ops(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		operation_count_value := input[0]
		if operation_count_value < 0 || operation_count_value > max_ops || int(length) != 1 + 2 * int(operation_count_value) { return -1 }
		operation_count := int(operation_count_value)
		mut active := [max_nodes]i64{}
		mut active_count := 0
		mut search_count := 0
		for index in 0 .. operation_count {
			operation := input[1 + 2 * index]
			key := input[2 + 2 * index]
			if operation < 0 || operation > 2 || key < -1000000 || key > 1000000 { return -1 }
			mut found := -1
			for i in 0 .. active_count { if active[i] == key { found = i; break } }
			if operation == 0 {
				if found >= 0 || active_count >= max_nodes { return -1 }
				active[active_count] = key
				active_count++
			} else if operation == 1 {
				search_count++
			} else {
				if found < 0 { return -1 }
				for i := found + 1; i < active_count; i++ { active[i - 1] = active[i] }
				active_count--
			}
		}
		mut nodes := [max_nodes]AvlNode{}
		for i in 0 .. max_nodes { nodes[i].left = -1; nodes[i].right = -1 }
		mut root := -1
		mut next := 0
		mut results := [max_ops]i64{}
		mut result_count := 0
		for index in 0 .. operation_count {
			operation := input[1 + 2 * index]
			key := input[2 + 2 * index]
			if operation == 0 { root = insert_node(&nodes[0], root, key, &next) }
			else if operation == 1 { results[result_count] = if contains(&nodes[0], root, key) { 1 } else { 0 }; result_count++ }
			else { root = delete_node(&nodes[0], root, key) }
		}
		bytes := (2 + active_count + search_count) * 8
		if output == nil || capacity < bytes { return -2 }
		put_i64(output, 0, i64(active_count))
		mut stack := [max_nodes]int{}
		mut top := 0
		mut current := root
		mut out_index := 1
		for current >= 0 || top > 0 {
			for current >= 0 { stack[top] = current; top++; current = nodes[current].left }
			top--
			current = stack[top]
			put_i64(output, out_index * 8, nodes[current].key)
			out_index++
			current = nodes[current].right
		}
		put_i64(output, out_index * 8, i64(search_count))
		out_index++
		for index in 0 .. search_count { put_i64(output, out_index * 8, results[index]); out_index++ }
		return i64(bytes)
	}
}
