module avltree_cpp_insert_only

const max_nodes = 256

fn avl_height(root int, left []int, right []int) int {
	if root < 0 { return 0 }
	return 1 + max(avl_height(left[root], left, right), avl_height(right[root], left, right))
}

fn avl_balance(root int, left []int, right []int) int {
	return avl_height(left[root], left, right) - avl_height(right[root], left, right)
}

fn rotate_right(root int, mut left []int, mut right []int) int {
	pivot := left[root]
	moved := right[pivot]
	right[pivot] = root
	left[root] = moved
	return pivot
}

fn rotate_left(root int, mut left []int, mut right []int) int {
	pivot := right[root]
	moved := left[pivot]
	left[pivot] = root
	right[root] = moved
	return pivot
}

fn insert_node(root int, key i32, mut keys []i32, mut left []int, mut right []int, mut next_node int) int {
	if root < 0 {
		node := next_node
		next_node++
		keys[node] = key
		left[node] = -1
		right[node] = -1
		return node
	}
	if key < keys[root] {
		left[root] = insert_node(left[root], key, mut keys, mut left, mut right, mut next_node)
	} else {
		right[root] = insert_node(right[root], key, mut keys, mut left, mut right, mut next_node)
	}
	balance := avl_balance(root, left, right)
	if balance > 1 {
		if avl_balance(left[root], left, right) < 0 {
			left[root] = rotate_left(left[root], mut left, mut right)
		}
		return rotate_right(root, mut left, mut right)
	}
	if balance < -1 {
		if avl_balance(right[root], left, right) > 0 {
			right[root] = rotate_right(right[root], mut left, mut right)
		}
		return rotate_left(root, mut left, mut right)
	}
	return root
}

fn store_i32_le(mut output &u8, position int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[position * 4 + byte] = u8(bits >> (8 * byte)) }
	}
}

fn emit_inorder(root int, keys []i32, left []int, right []int,
	mut output &u8, mut position &int) {
	if root < 0 { return }
	emit_inorder(left[root], keys, left, right, mut output, mut position)
	store_i32_le(mut output, position, keys[root])
	position++
	emit_inorder(right[root], keys, left, right, mut output, mut position)
}

@[export: 'avltree_cpp_insert_only']
pub fn avltree_cpp_insert_only(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || length > max_nodes + 1 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_nodes { return -1 }
		count := int(input[0])
		if length != usize(count + 1) { return -1 }
		for index in 0 .. count {
			key := input[index + 1]
			if key < -2147483648 || key > 2147483647 { return -1 }
			for previous in 0 .. index {
				if input[previous + 1] == key { return -1 }
			}
		}
		required := count * 4
		if output == nil || output_capacity < usize(required) { return -2 }

		mut keys := []i32{len: max_nodes}
		mut left := []int{len: max_nodes, init: -1}
		mut right := []int{len: max_nodes, init: -1}
		mut next_node := 0
		mut root := -1
		for index in 0 .. count {
			root = insert_node(root, i32(input[index + 1]), mut keys, mut left, mut right, mut next_node)
		}
		mut position := 0
		emit_inorder(root, keys, left, right, mut output, mut position)
		return i64(position)
	}
}
