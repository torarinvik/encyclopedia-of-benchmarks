/*
Copyright (C) 1996 McGill University.
Copyright (C) 1996 McCAT System Group.
Copyright (C) 1996 ACAPS Benchmark Administrator
                   benadmin@acaps.cs.mcgill.ca

This program is free software; you can redistribute it and/or modify
it provided this copyright notice is maintained.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

module mccat_bintr

import math

const max_nodes = 64
const query_count = 100
const output_bytes = 33

struct TreeNode {
mut:
	value i32
	left int
	right int
}

fn tree_size(tree &TreeNode, node int) int {
	if node < 0 { return 0 }
	unsafe { return 1 + tree_size(tree, tree[node].left) + tree_size(tree, tree[node].right) }
}

fn tree_sum(tree &TreeNode, node int) f64 {
	if node < 0 { return 0.0 }
	unsafe { return f64(tree[node].value) + tree_sum(tree, tree[node].left) + tree_sum(tree, tree[node].right) }
}

fn member_dfs(tree &TreeNode, node int, sought i32) bool {
	if node < 0 { return false }
	unsafe {
		if tree[node].value == sought { return true }
		if member_dfs(tree, tree[node].left, sought) { return true }
		return member_dfs(tree, tree[node].right, sought)
	}
}

fn put_u32_le(mut output &u8, offset int, value u32) {
	unsafe { for byte in 0 .. 4 { output[offset + byte] = u8((value >> u32(8 * byte)) & 255) } }
}

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'mccat_bintr']
pub fn mccat_bintr(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 103 || length > usize(max_nodes + 102) { return -1 }
	unsafe {
		node_count_value := input[0]
		if node_count_value < 1 || node_count_value > i64(max_nodes) { return -1 }
		node_count := int(node_count_value)
		if length != usize(node_count + 102) || input[node_count + 1] != i64(query_count) { return -1 }
		for i in 0 .. node_count {
			value := input[i + 1]
			if value == 0 || value < -32768 || value > 32767 { return -1 }
		}
		for i in 0 .. query_count {
			value := input[node_count + 2 + i]
			if value == 0 || value < -32768 || value > 32767 { return -1 }
		}
		if output == nil || capacity < usize(output_bytes) { return -2 }

		mut tree := [max_nodes]TreeNode{}
		mut root := -1
		mut used := 0
		for i in 0 .. node_count {
			value := i32(input[i + 1])
			if root < 0 {
				root = 0
				tree[0] = TreeNode{value: value, left: -1, right: -1}
				used = 1
				continue
			}
			mut current := root
			for {
				if value == tree[current].value { break }
				if value < tree[current].value {
					if tree[current].left < 0 {
						tree[current].left = used
						tree[used] = TreeNode{value: value, left: -1, right: -1}
						used++
						break
					}
					current = tree[current].left
				} else {
					if tree[current].right < 0 {
						tree[current].right = used
						tree[used] = TreeNode{value: value, left: -1, right: -1}
						used++
						break
					}
					current = tree[current].right
				}
			}
		}

		size := tree_size(&tree[0], root)
		sum := tree_sum(&tree[0], root)
		mean := sum / f64(size)
		mut staged := [output_bytes]u8{}
		put_u32_le(mut &staged[0], 0, u32(size))
		put_f64_le(mut &staged[0], 4, sum)
		put_f64_le(mut &staged[0], 12, mean)
		for i in 0 .. query_count {
			if member_dfs(&tree[0], root, i32(input[node_count + 2 + i])) {
				staged[20 + i / 8] |= u8(1 << (i & 7))
			}
		}
		for i in 0 .. output_bytes { output[i] = staged[i] }
		return output_bytes
	}
}
