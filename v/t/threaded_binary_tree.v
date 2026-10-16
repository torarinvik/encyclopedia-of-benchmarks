module threaded_binary_tree

import core:c

const max_nodes = 128

struct Node {
	key i32
	left int
	right int
	left_is_thread bool
	right_is_thread bool
}

fn put_i32_le(mut output &u8, offset int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'threaded_binary_tree']
pub fn threaded_binary_tree(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > i64(max_nodes) { return -1 }
		count := int(input[0])
		if length != usize(1 + input[0]) { return -1 }
		for i in 0 .. count {
			if input[i + 1] < i64(-2147483648) || input[i + 1] > i64(2147483647) { return -1 }
		}

		required := count * 4
		if required > 0 && (unsafe { output == nil } || output_capacity < required) { return -2 }

		mut nodes := []Node{len: max_nodes}
		mut root := -1
		for inserted in 0 .. count {
			node := inserted
			key := i32(input[inserted + 1])
			nodes[node] = Node{key: key, left: -1, right: -1, left_is_thread: false, right_is_thread: false}
			if root == -1 {
				root = node
				continue
			}

			mut current := root
			mut parent := -1
			for {
				parent = current
				if key < nodes[current].key {
					if !nodes[current].left_is_thread && nodes[current].left != -1 { current = nodes[current].left } else { break }
				} else {
					if !nodes[current].right_is_thread && nodes[current].right != -1 { current = nodes[current].right } else { break }
				}
			}

			if key < nodes[parent].key {
				nodes[node].left = nodes[parent].left
				nodes[node].left_is_thread = nodes[parent].left_is_thread
				nodes[node].right = parent
				nodes[node].right_is_thread = true
				nodes[parent].left = node
				nodes[parent].left_is_thread = false
			} else {
				nodes[node].right = nodes[parent].right
				nodes[node].right_is_thread = nodes[parent].right_is_thread
				nodes[node].left = parent
				nodes[node].left_is_thread = true
				nodes[parent].right = node
				nodes[parent].right_is_thread = false
			}
		}

		mut current := root
		for current != -1 && !nodes[current].left_is_thread && nodes[current].left != -1 {
			current = nodes[current].left
		}
		mut written := 0
		for current != -1 {
			put_i32_le(mut output, written, nodes[current].key)
			written += 4
			if nodes[current].right_is_thread {
				current = nodes[current].right
			} else {
				current = nodes[current].right
				for current != -1 && !nodes[current].left_is_thread && nodes[current].left != -1 {
					current = nodes[current].left
				}
			}
		}
		return i64(written)
	}
}
