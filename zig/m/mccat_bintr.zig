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

const max_nodes: usize = 64;
const query_count: usize = 100;
const output_bytes: usize = 33;

const TreeNode = struct {
    value: i32,
    left: i32,
    right: i32,
};

fn treeSize(tree: [*]const TreeNode, node: i32) u32 {
    if (node < 0) return 0;
    const index: usize = @intCast(node);
    return 1 + treeSize(tree, tree[index].left) + treeSize(tree, tree[index].right);
}

fn treeSum(tree: [*]const TreeNode, node: i32) f64 {
    if (node < 0) return 0.0;
    const index: usize = @intCast(node);
    return @as(f64, @floatFromInt(tree[index].value))
        + treeSum(tree, tree[index].left) + treeSum(tree, tree[index].right);
}

fn memberDfs(tree: [*]const TreeNode, node: i32, sought: i32) bool {
    if (node < 0) return false;
    const index: usize = @intCast(node);
    if (tree[index].value == sought) return true;
    if (memberDfs(tree, tree[index].left, sought)) return true;
    return memberDfs(tree, tree[index].right, sought);
}

fn putU32Le(output: [*]u8, offset: usize, value: u32) void {
    for (0..4) |byte| output[offset + byte] = @truncate(value >> @intCast(8 * byte));
}

fn putF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn mccat_bintr(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (length < 103 or length > max_nodes + 102) return -1;
    const node_count_value = values[0];
    if (node_count_value < 1 or node_count_value > 64) return -1;
    const node_count: usize = @intCast(node_count_value);
    if (length != node_count + 102 or values[node_count + 1] != 100) return -1;
    for (0..node_count) |i| {
        const value = values[i + 1];
        if (value == 0 or value < -32768 or value > 32767) return -1;
    }
    for (0..query_count) |i| {
        const value = values[node_count + 2 + i];
        if (value == 0 or value < -32768 or value > 32767) return -1;
    }
    const out = output orelse return -2;
    if (capacity < output_bytes) return -2;

    var tree: [max_nodes]TreeNode = undefined;
    var root: i32 = -1;
    var used: i32 = 0;
    for (0..node_count) |i| {
        const value: i32 = @intCast(values[i + 1]);
        if (root < 0) {
            root = 0;
            tree[0] = .{ .value = value, .left = -1, .right = -1 };
            used = 1;
            continue;
        }
        var current = root;
        while (true) {
            const index: usize = @intCast(current);
            if (value == tree[index].value) break;
            if (value < tree[index].value) {
                if (tree[index].left < 0) {
                    tree[index].left = used;
                    tree[@intCast(used)] = .{ .value = value, .left = -1, .right = -1 };
                    used += 1;
                    break;
                }
                current = tree[index].left;
            } else {
                if (tree[index].right < 0) {
                    tree[index].right = used;
                    tree[@intCast(used)] = .{ .value = value, .left = -1, .right = -1 };
                    used += 1;
                    break;
                }
                current = tree[index].right;
            }
        }
    }

    const size = treeSize(&tree, root);
    const sum = treeSum(&tree, root);
    const mean = sum / @as(f64, @floatFromInt(size));
    var staged: [output_bytes]u8 = @splat(0);
    putU32Le(&staged, 0, size);
    putF64Le(&staged, 4, sum);
    putF64Le(&staged, 12, mean);
    for (0..query_count) |i| {
        if (memberDfs(&tree, root, @intCast(values[node_count + 2 + i]))) {
            staged[20 + i / 8] |= @as(u8, 1) << @as(u3, @intCast(i % 8));
        }
    }
    @memcpy(out[0..output_bytes], staged[0..]);
    return output_bytes;
}
