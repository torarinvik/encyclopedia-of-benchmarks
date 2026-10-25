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

package mccat_bintr

import "core:c"

MAX_NODES :: 64
QUERY_COUNT :: 100
OUTPUT_BYTES :: 33

Tree_Node :: struct { value: i32, left: i32, right: i32 }

tree_size :: proc "contextless" (tree: [^]Tree_Node, node: i32) -> i32 {
    if node < 0 do return 0
    return 1 + tree_size(tree, tree[node].left) + tree_size(tree, tree[node].right)
}

tree_sum :: proc "contextless" (tree: [^]Tree_Node, node: i32) -> f64 {
    if node < 0 do return 0.0
    return f64(tree[node].value) + tree_sum(tree, tree[node].left) + tree_sum(tree, tree[node].right)
}

member_dfs :: proc "contextless" (tree: [^]Tree_Node, node: i32, sought: i32) -> bool {
    if node < 0 do return false
    if tree[node].value == sought do return true
    if member_dfs(tree, tree[node].left, sought) do return true
    return member_dfs(tree, tree[node].right, sought)
}

put_u32_le :: proc "contextless" (output: [^]u8, offset: int, value: u32) {
    for i := 0; i < 4; i += 1 { output[offset+i] = u8(value >> (8*i)) }
}

put_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
    bits := transmute(u64, value)
    for i := 0; i < 8; i += 1 { output[offset+i] = u8(bits & 255); bits >>= 8 }
}

@(export)
mccat_bintr :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 103 || length > MAX_NODES + 102 do return -1
    node_count_value := input[0]
    if node_count_value < 1 || node_count_value > MAX_NODES do return -1
    node_count := c.size_t(node_count_value)
    if length != node_count + 102 || input[node_count+1] != QUERY_COUNT do return -1
    for i := c.size_t(0); i < node_count; i += 1 {
        if input[i+1] == 0 || input[i+1] < -32768 || input[i+1] > 32767 do return -1
    }
    for i := c.size_t(0); i < QUERY_COUNT; i += 1 {
        value := input[node_count+2+i]
        if value == 0 || value < -32768 || value > 32767 do return -1
    }
    if output == nil || capacity < OUTPUT_BYTES do return -2

    tree: [MAX_NODES]Tree_Node
    root := -1
    used := 0
    for i := c.size_t(0); i < node_count; i += 1 {
        value := i32(input[i+1])
        if root < 0 {
            root = 0
            tree[0] = Tree_Node{value=value,left=-1,right=-1}
            used = 1
            continue
        }
        current := root
        for {
            if value == tree[current].value do break
            if value < tree[current].value {
                if tree[current].left < 0 {
                    tree[current].left = used
                    tree[used] = Tree_Node{value=value,left=-1,right=-1}
                    used += 1
                    break
                }
                current = tree[current].left
            } else {
                if tree[current].right < 0 {
                    tree[current].right = used
                    tree[used] = Tree_Node{value=value,left=-1,right=-1}
                    used += 1
                    break
                }
                current = tree[current].right
            }
        }
    }
    size := tree_size(&tree[0], root)
    sum := tree_sum(&tree[0], root)
    mean := sum / f64(size)
    for i := 0; i < OUTPUT_BYTES; i += 1 { output[i] = 0 }
    put_u32_le(output, 0, u32(size))
    put_f64_le(output, 4, sum)
    put_f64_le(output, 12, mean)
    for i := 0; i < QUERY_COUNT; i += 1 {
        if member_dfs(&tree[0], root, i32(input[node_count+2+c.size_t(i)])) {
            output[20+i/8] |= u8(1 << (i & 7))
        }
    }
    return OUTPUT_BYTES
}
