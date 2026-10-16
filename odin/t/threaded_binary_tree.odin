package threaded_binary_tree

import "core:c"

MAX_NODES :: 128
Node :: struct {
	key: i32,
	left: int,
	right: int,
	left_is_thread: bool,
	right_is_thread: bool,
}

put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8(bits >> (8 * byte))
	}
}

@(export)
threaded_binary_tree :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	if input[0] < 0 || input[0] > i64(MAX_NODES) do return -1
	count := int(input[0])
	if length != c.size_t(1 + count) do return -1
	for i := 0; i < count; i += 1 {
		if input[i + 1] < -2147483648 || input[i + 1] > 2147483647 do return -1
	}

	required := count * 4
	if required > 0 && (output == nil || output_capacity < c.size_t(required)) do return -2

	var nodes: [MAX_NODES]Node
	root := -1
	for inserted := 0; inserted < count; inserted += 1 {
		node := inserted
		key := i32(input[inserted + 1])
		nodes[node] = Node{key, -1, -1, false, false}
		if root == -1 {
			root = node
			continue
		}

		current := root
		parent := -1
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

	current := root
	for current != -1 && !nodes[current].left_is_thread && nodes[current].left != -1 {
		current = nodes[current].left
	}
	written := 0
	for current != -1 {
		put_i32_le(output, written, nodes[current].key)
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
