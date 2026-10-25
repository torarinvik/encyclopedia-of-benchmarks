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

const MAX_NODES: usize = 64;
const QUERY_COUNT: usize = 100;
const OUTPUT_BYTES: usize = 33;

#[derive(Clone, Copy)]
struct TreeNode { value: i32, left: i32, right: i32 }

fn tree_size(tree: &[TreeNode; MAX_NODES], node: i32) -> u32 {
    if node < 0 { return 0; }
    1 + tree_size(tree, tree[node as usize].left) + tree_size(tree, tree[node as usize].right)
}

fn tree_sum(tree: &[TreeNode; MAX_NODES], node: i32) -> f64 {
    if node < 0 { return 0.0; }
    f64::from(tree[node as usize].value)
        + tree_sum(tree, tree[node as usize].left)
        + tree_sum(tree, tree[node as usize].right)
}

fn member_dfs(tree: &[TreeNode; MAX_NODES], node: i32, sought: i32) -> bool {
    if node < 0 { return false; }
    if tree[node as usize].value == sought { return true; }
    if member_dfs(tree, tree[node as usize].left, sought) { return true; }
    member_dfs(tree, tree[node as usize].right, sought)
}

#[no_mangle]
pub unsafe extern "C" fn mccat_bintr(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 103 || length > MAX_NODES + 102 { return -1; }
    let node_count_value = *input;
    if !(1..=MAX_NODES as i64).contains(&node_count_value) { return -1; }
    let node_count = node_count_value as usize;
    if length != node_count + 102 || *input.add(node_count + 1) != QUERY_COUNT as i64 { return -1; }
    let nodes = std::slice::from_raw_parts(input.add(1), node_count);
    let probes = std::slice::from_raw_parts(input.add(node_count + 2), QUERY_COUNT);
    if nodes.iter().any(|&x| x == 0 || !(-32768..=32767).contains(&x))
        || probes.iter().any(|&x| x == 0 || !(-32768..=32767).contains(&x)) { return -1; }
    if output.is_null() || capacity < OUTPUT_BYTES { return -2; }

    let empty = TreeNode { value: 0, left: -1, right: -1 };
    let mut tree = [empty; MAX_NODES];
    let mut root = -1i32;
    let mut used = 0i32;
    for &raw_value in nodes {
        let value = raw_value as i32;
        if root < 0 {
            root = 0;
            tree[0] = TreeNode { value, left: -1, right: -1 };
            used = 1;
            continue;
        }
        let mut current = root;
        loop {
            let slot = current as usize;
            if value == tree[slot].value { break; }
            let branch = if value < tree[slot].value { &mut tree[slot].left } else { &mut tree[slot].right };
            if *branch < 0 {
                *branch = used;
                tree[used as usize] = TreeNode { value, left: -1, right: -1 };
                used += 1;
                break;
            }
            current = *branch;
        }
    }

    let size = tree_size(&tree, root);
    let sum = tree_sum(&tree, root);
    let mean = sum / f64::from(size);
    let mut staged = [0u8; OUTPUT_BYTES];
    staged[0..4].copy_from_slice(&size.to_le_bytes());
    staged[4..12].copy_from_slice(&sum.to_le_bytes());
    staged[12..20].copy_from_slice(&mean.to_le_bytes());
    for (index, &probe) in probes.iter().enumerate() {
        if member_dfs(&tree, root, probe as i32) { staged[20 + index / 8] |= 1 << (index & 7); }
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, OUTPUT_BYTES);
    OUTPUT_BYTES as i64
}
